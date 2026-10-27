mock_provider "aws" {
  source = "./tests/mocks"
}

mock_provider "archive" {}
mock_provider "helm" {}
mock_provider "kubectl" {}
mock_provider "kubernetes" {}
mock_provider "random" {}

variables {
  eks_cluster_name = "radar-base-test"
  radar_postgres_password = "test"
  docker_hub_username     = "test"
  docker_hub_access_token = "test"
  ghcr_username           = "test"
  ghcr_access_token       = "test"
  domain_name             = { "radar-base.test" = "Z0123456789ABCDEFGHIJ" }
  enable_metrics          = false
  enable_karpenter        = false
  enable_msk              = false
  enable_rds              = false
  enable_route53          = true
  enable_ses              = true
  enable_s3               = false
  enable_eip              = true
  enable_ecr_ptc          = false
  with_dmz_pods           = false
  ses_bounce_destinations = []

  AWS_ACCESS_KEY_ID       = "test"
  AWS_SECRET_ACCESS_KEY   = "test"
}

run "ses_plans_the_full_identity_graph" {
  command = plan

  assert {
    condition = alltrue([
      length(aws_ses_domain_identity.smtp_identity) == 1,
      length(aws_ses_domain_dkim.smtp_dkim) == 1,
      length(aws_ses_domain_mail_from.smtp_mail_from) == 1,
      length(aws_route53_record.smtp_dkim_record) == 3,
      length(aws_route53_record.smtp_mail_from_mx) == 1,
      length(aws_route53_record.smtp_mail_from_txt) == 1,
      length(aws_route53_record.smtp_dmarc) == 1,
      length(aws_ses_configuration_set.configuration_set) == 1,
      length(aws_sns_topic.ses_bounce_event_topic) == 1,
      length(aws_ses_identity_notification_topic.ses_bounce_domain_identity) == 1,
      length(aws_ses_identity_notification_topic.ses_complaint_domain_identity) == 1,
      length(aws_ses_event_destination.sns) == 1,
    ])
    error_message = "The enable_ses with a single domain should plan the complete SES identity and notification graph"
  }

  assert {
    condition     = aws_ses_domain_identity.smtp_identity[0].domain == "dev.radar-base.test"
    error_message = "The SES identity should be the environment prefixed onto the domain"
  }

  assert {
    condition     = one(aws_ses_configuration_set.configuration_set[0].delivery_options).tls_policy == "Require"
    error_message = "The SES configuration set should require TLS"
  }

  assert {
    condition = alltrue([
      aws_ses_event_destination.sns[0].enabled,
      toset(aws_ses_event_destination.sns[0].matching_types) == toset(["bounce", "complaint"]),
      aws_ses_event_destination.sns[0].name == "radar-base-test-ses-event-destination-sns",
    ])
    error_message = "The event destination should forward bounce and complaint events"
  }
}

run "ses_publishes_three_dkim_records" {
  command = plan

  assert {
    condition     = length(aws_route53_record.smtp_dkim_record) == 3
    error_message = "SES DKIM uses three tokens so three records should be planned"
  }

  assert {
    condition = alltrue([
      aws_route53_record.smtp_dkim_record[0].type == "CNAME",
      aws_route53_record.smtp_dkim_record[1].type == "CNAME",
      aws_route53_record.smtp_dkim_record[2].type == "CNAME",
    ])
    error_message = "Every DKIM record should be a CNAME"
  }

  assert {
    condition = alltrue([
      aws_route53_record.smtp_dkim_record[0].ttl == 600,
      aws_route53_record.smtp_dkim_record[1].ttl == 600,
      aws_route53_record.smtp_dkim_record[2].ttl == 600,
    ])
    error_message = "Every DKIM record should use a 600 second TTL"
  }

  assert {
    condition = alltrue([
      aws_route53_record.smtp_dkim_record[0].zone_id == "Z0123456789ABCDEFGHIJ",
      aws_route53_record.smtp_dkim_record[1].zone_id == "Z0123456789ABCDEFGHIJ",
      aws_route53_record.smtp_dkim_record[2].zone_id == "Z0123456789ABCDEFGHIJ",
    ])
    error_message = "Every DKIM record should land in the hosted zone"
  }
}

run "ses_publishes_mail_from_and_dmarc_records" {
  command = plan

  assert {
    condition = alltrue([
      aws_route53_record.smtp_mail_from_mx[0].type == "MX",
      aws_route53_record.smtp_mail_from_mx[0].ttl == 600,
      aws_route53_record.smtp_mail_from_txt[0].type == "TXT",
      toset(aws_route53_record.smtp_mail_from_txt[0].records) == toset(["v=spf1 include:amazonses.com ~all"]),
    ])
    error_message = "The MAIL FROM records should publish the regional feedback MX and the SPF include"
  }

  assert {
    condition = alltrue([
      aws_route53_record.smtp_dmarc[0].name == "_dmarc.dev.radar-base.test",
      aws_route53_record.smtp_dmarc[0].type == "TXT",
      aws_route53_record.smtp_dmarc[0].ttl == 300,
      toset(aws_route53_record.smtp_dmarc[0].records) == toset(["v=DMARC1; p=none;"]),
    ])
    error_message = "The DMARC record should be a monitoring-only TXT record"
  }
}

run "ses_creates_an_smtp_user_restricted_to_send_raw_email" {
  command = plan

  assert {
    condition = alltrue([
      length(aws_iam_user.smtp_user) == 1,
      length(aws_iam_access_key.smtp_user_key) == 1,
      length(aws_iam_policy.smtp_user_policy) == 1,
      length(aws_iam_user_policy_attachment.smtp_user_policy_attach) == 1,
    ])
    error_message = "The enable_ses should plan an SMTP IAM user, access key, policy and attachment"
  }

  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_policy.smtp_user_policy[0].policy).Statement :
      statement.Action == ["ses:SendRawEmail"] && statement.Resource == "*"
    ])
    error_message = "The SMTP policy should allow only ses:SendRawEmail"
  }

  assert {
    condition     = aws_iam_user.smtp_user[0].name == "${var.eks_cluster_name}-smtp-user"
    error_message = "The SMTP user should be named after the cluster"
  }
}

run "ses_smtp_endpoint_outputs_are_populated" {
  command = plan

  assert {
    condition     = output.radar_base_smtp_host == "email-smtp.eu-west-2.amazonaws.com"
    error_message = "The SMTP host should be the regional SES endpoint"
  }

  assert {
    condition     = output.radar_base_smtp_port == 587
    error_message = "The SMTP port should be the submission port 587"
  }
}

run "route53_creates_a_cname_per_service_prefix" {
  command = plan

  assert {
    condition     = length(local.cname_prefixes) == 6
    error_message = "local.cname_prefixes should list the documented service prefixes"
  }

  assert {
    condition     = length(aws_route53_record.this) == 6
    error_message = "The enable_route53 should create one CNAME per service prefix"
  }

  assert {
    condition     = toset(keys(aws_route53_record.this)) == toset(local.cname_prefixes)
    error_message = "The CNAME record keys should match local.cname_prefixes"
  }

  assert {
    condition = alltrue([
      aws_route53_record.this["grafana"].name == "grafana.dev.radar-base.test",
      aws_route53_record.this["prometheus"].name == "prometheus.dev.radar-base.test",
      aws_route53_record.this["alertmanager"].name == "alertmanager.dev.radar-base.test",
    ])
    error_message = "Each CNAME should be <prefix>.<environment>.<domain>"
  }

  assert {
    condition = alltrue([
      toset(aws_route53_record.this["grafana"].records) == toset(["dev.radar-base.test"]),
      aws_route53_record.this["grafana"].type == "CNAME",
      aws_route53_record.this["grafana"].ttl == 300,
      aws_route53_record.this["grafana"].zone_id == "Z0123456789ABCDEFGHIJ",
    ])
    error_message = "Service CNAMEs should be 300 second records aliasing the domain"
  }
}

run "route53__record_requires_the_elastic_ip" {
  command = plan

  assert {
    condition     = length(aws_route53_record.main) == 1
    error_message = "With enable_route53 and enable_eip both set, the apex record should be planned"
  }

  assert {
    condition = alltrue([
      aws_route53_record.main[0].name == "dev.radar-base.test",
      aws_route53_record.main[0].type == "CNAME",
      aws_route53_record.main[0].ttl == 300,
    ])
    error_message = "The record should alias the environment domain with a 300 second TTL"
  }
}

run "route53_record_is_skipped_without_an_elastic_ip" {
  command = plan

  variables {
    enable_eip = false
  }

  assert {
    condition     = length(aws_route53_record.main) == 0
    error_message = "The record should be skipped when there is no Elastic IP to point at"
  }

  assert {
    condition     = length(aws_route53_record.this) == 6
    error_message = "Service CNAMEs should still be created without an Elastic IP"
  }
}

run "route53_creates_both_irsa_roles" {
  command = plan

  assert {
    condition = alltrue([
      length(module.external_dns_irsa) == 1,
      length(module.cert_manager_irsa) == 1,
    ])
    error_message = "The enable_route53 should create the external-dns and cert-manager IRSA roles"
  }

  assert {
    condition     = local.aws_account == "123456789012" && local.oidc_issuer == "oidc.eks.eu-west-2.amazonaws.com/id/0123456789ABCDEF"
    error_message = "The IRSA provider ARN is built from local.aws_account and local.oidc_issuer"
  }
}

run "route53_hosted_zone_output_is_populated" {
  command = plan

  assert {
    condition     = output.radar_base_route53_hosted_zone_id == "Z0123456789ABCDEFGHIJ"
    error_message = "The hosted zone output should forward the zone ID"
  }
}

run "disabling_route53_removes_dns_and_ses_identity_resources" {
  command = plan

  variables {
    enable_route53 = false
  }

  assert {
    condition = alltrue([
      length(aws_route53_record.this) == 0,
      length(aws_route53_record.main) == 0,
      length(aws_route53_record.smtp_dkim_record) == 0,
      length(aws_route53_record.smtp_mail_from_mx) == 0,
      length(aws_route53_record.smtp_mail_from_txt) == 0,
      length(aws_route53_record.smtp_dmarc) == 0,
      length(aws_ses_domain_identity.smtp_identity) == 0,
      length(aws_ses_domain_dkim.smtp_dkim) == 0,
      length(aws_ses_domain_mail_from.smtp_mail_from) == 0,
      length(module.external_dns_irsa) == 0,
      length(module.cert_manager_irsa) == 0,
      output.radar_base_route53_hosted_zone_id == null,
    ])
    error_message = "Turning enable_route53 off should remove every DNS record and SES identity resource"
  }

  assert {
    condition = alltrue([
      length(aws_iam_user.smtp_user) == 1,
      length(aws_iam_access_key.smtp_user_key) == 1,
      length(aws_iam_policy.smtp_user_policy) == 1,
      output.radar_base_smtp_host == "email-smtp.eu-west-2.amazonaws.com",
    ])
    error_message = "The SMTP user and endpoint outputs depend only on enable_ses set to true"
  }
}

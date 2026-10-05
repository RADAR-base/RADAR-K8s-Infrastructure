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
  domain_name = { "radar-base.test" = "Z0123456789ABCDEFGHIJ" }
  enable_metrics   = false
  enable_karpenter = false
  enable_msk       = false
  enable_rds       = false
  enable_route53   = false
  enable_ses       = false
  enable_s3        = false
  enable_eip       = false
  enable_ecr_ptc   = false
  with_dmz_pods    = false
  ses_bounce_destinations = []

  AWS_ACCESS_KEY_ID       = "test"
  AWS_SECRET_ACCESS_KEY   = "test"
  radar_postgres_password = "test"
  docker_hub_username     = "test"
  docker_hub_access_token = "test"
  ghcr_username           = "test"
  ghcr_access_token       = "test"
}

run "no_optional_resources_are_planned" {
  command = plan

  assert {
    condition = alltrue([
      length(aws_db_instance.radar_postgres) == 0,
      length(aws_db_instance.radar_postgres_replicas) == 0,
      length(aws_db_subnet_group.rds_subnet) == 0,
      length(aws_security_group.rds_access) == 0,
      length(kubectl_manifest.create_databases_if_not_exist) == 0,
      length(aws_s3_bucket.this) == 0,
      length(aws_s3_bucket_ownership_controls.this) == 0,
      length(aws_s3_bucket_server_side_encryption_configuration.this) == 0,
      length(aws_iam_user.s3_access) == 0,
      length(aws_iam_policy.s3_access) == 0,
      length(aws_iam_access_key.s3_access) == 0,
      length(aws_eip.cluster_loadbalancer_eip) == 0,
      length(aws_msk_cluster.msk_cluster) == 0,
      length(aws_msk_configuration.msk_configuration) == 0,
      length(aws_cloudwatch_log_group.msk_broker) == 0,
      length(aws_security_group.msk_cluster_access) == 0,
      length(aws_ses_domain_identity.smtp_identity) == 0,
      length(aws_ses_configuration_set.configuration_set) == 0,
      length(aws_sns_topic.ses_bounce_event_topic) == 0,
      length(aws_iam_user.smtp_user) == 0,
      length(aws_iam_role.ecr_repository_creator) == 0,
      length(aws_iam_policy.ecr_repository_permissions) == 0,
      length(aws_secretsmanager_secret.dockerhub_credentials) == 0,
      length(aws_secretsmanager_secret.ghcr_credentials) == 0,
      length(aws_ecr_pull_through_cache_rule.dockerhub) == 0,
      length(aws_ecr_repository_creation_template.dockerhub) == 0,
      length(aws_ecr_repository_creation_template.ghcr) == 0,
      length(helm_release.metrics_server) == 0,
      length(helm_release.headlamp) == 0,
      length(kubernetes_namespace.headlamp) == 0,
      length(kubernetes_cluster_role_v1.read_only) == 0,
      length(kubectl_manifest.karpenter_node_class) == 0,
      length(kubectl_manifest.karpenter_node_pool) == 0,
      length(helm_release.karpenter) == 0,
      length(module.karpenter) == 0,
      length(module.external_dns_irsa) == 0,
      length(module.cert_manager_irsa) == 0,
      length(aws_route53_record.this) == 0,
      length(aws_route53_record.main) == 0,
    ])
    error_message = "No optional resources are created with every enable_* flag set to false"
  }
}

run "optional_outputs_are_null" {
  command = plan

  assert {
    condition = alltrue([
      output.radar_base_rds_managementportal_host == null,
      output.radar_base_rds_appserver_port == null,
      output.radar_base_rds_kratos_username == null,
      output.radar_base_rds_hydra_host == null,
      output.radar_base_rds_rest_sources_auth_port == null,
      output.radar_base_rds_replicas_info == null,
      output.radar_base_s3_intermediate_output_bucket_name == null,
      output.radar_base_s3_output_bucket_name == null,
      output.radar_base_s3_velero_bucket_name == null,
      output.radar_base_eip_allocation_id == null,
      output.radar_base_eip_public_dns == null,
      output.radar_base_msk_bootstrap_brokers == null,
      output.radar_base_msk_zookeeper_connect == null,
      output.radar_base_headlamp_user_token == null,
      output.radar_base_route53_hosted_zone_id == null,
      output.radar_base_smtp_host == null,
      output.radar_base_smtp_port == null,
      output.radar_base_smtp_username == null,
    ])
    error_message = "No outputs for optional resources with every enable_* flag set to false"
  }
}

run "cluster_derived_locals_are_populated_from_mock_data" {
  command = plan

  assert {
    condition     = local.aws_account == "123456789012"
    error_message = "local.aws_account should be the account ID parsed out of the mocked EKS cluster ARN"
  }

  assert {
    condition     = local.oidc_issuer == "oidc.eks.eu-west-2.amazonaws.com/id/0123456789ABCDEF"
    error_message = "local.oidc_issuer should be the issuer with the https:// scheme stripped"
  }

  assert {
    condition     = local.worker_node_group.node_group_name == "worker-radar-base-test-20260410000000"
    error_message = "local.worker_node_group should resolve the single mocked worker node group"
  }

  assert {
    condition     = local.worker_node_zones == ["eu-west-2a"]
    error_message = "local.worker_node_zones should contain the single AZ backing the worker's subnet"
  }
}

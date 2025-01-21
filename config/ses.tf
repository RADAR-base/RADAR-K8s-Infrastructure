resource "aws_ses_domain_identity" "smtp_identity" {
  count  = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  domain = keys(var.domain_name)[0]
}

resource "aws_ses_domain_dkim" "smtp_dkim" {
  count  = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  domain = aws_ses_domain_identity.smtp_identity[0].domain
}

resource "aws_route53_record" "smtp_dkim_record" {
  count   = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 3 : 0
  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "${aws_ses_domain_dkim.smtp_dkim[0].dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.smtp_dkim[0].dkim_tokens[count.index]}.dkim.amazonses.com"]

  depends_on = [aws_route53_zone.primary]
}

resource "aws_ses_domain_mail_from" "smtp_mail_from" {
  count = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0

  domain           = aws_ses_domain_identity.smtp_identity[0].domain
  mail_from_domain = "info.${var.environment}.${aws_ses_domain_identity.smtp_identity[0].domain}"
}

resource "aws_route53_record" "smtp_mail_from_mx" {
  count   = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  zone_id = aws_route53_zone.primary[0].zone_id
  name    = aws_ses_domain_mail_from.smtp_mail_from[0].mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.AWS_REGION}.amazonses.com"]

  depends_on = [aws_route53_zone.primary]
}

resource "aws_ses_configuration_set" "configuration_set" {
  count = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  name  = "${var.eks_cluster_name}-ses-configuration-set"
}


resource "aws_sns_topic" "ses_bounce_event_topic" {
  count = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  name  = "${var.eks_cluster_name}-ses-bounce-event-topic"

  # trivy:ignore:AVD-AWS-0136 The CMK requirement should stay optional and by default an AWS managed key is used for encryption
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "ses_bounce_event_subscriptions" {
  for_each = toset(var.ses_bounce_destinations)

  topic_arn = aws_sns_topic.ses_bounce_event_topic[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_ses_identity_notification_topic" "ses_bounce_domain_identity" {
  count                    = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  topic_arn                = aws_sns_topic.ses_bounce_event_topic[0].arn
  notification_type        = "Bounce"
  identity                 = keys(var.domain_name)[0]
  include_original_headers = true
}

resource "aws_ses_identity_notification_topic" "ses_complaint_domain_identity" {
  count                    = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  topic_arn                = aws_sns_topic.ses_bounce_event_topic[0].arn
  notification_type        = "Complaint"
  identity                 = keys(var.domain_name)[0]
  include_original_headers = true
}

resource "aws_ses_event_destination" "sns" {
  count                  = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  name                   = "${var.eks_cluster_name}-ses-event-destination-sns"
  configuration_set_name = aws_ses_configuration_set.configuration_set[0].name
  enabled                = true
  matching_types         = ["bounce", "complaint"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_bounce_event_topic[0].arn
  }
}

resource "aws_route53_record" "smtp_mail_from_txt" {
  count   = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  zone_id = aws_route53_zone.primary[0].zone_id
  name    = aws_ses_domain_mail_from.smtp_mail_from[0].mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]

  depends_on = [aws_route53_zone.primary]
}

resource "aws_route53_record" "smtp_dmarc" {
  count   = var.enable_route53 && length(var.domain_name) == 1 && var.enable_ses ? 1 : 0
  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "_dmarc.${keys(var.domain_name)[0]}"
  type    = "TXT"
  ttl     = "300"
  records = ["v=DMARC1; p=none;"]

  depends_on = [aws_route53_zone.primary]
}

resource "aws_iam_user" "smtp_user" {
  count = var.enable_ses ? 1 : 0

  name = "${var.eks_cluster_name}-smtp-user"
  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-smtp-user" }), var.common_tags)
}

resource "aws_iam_access_key" "smtp_user_key" {
  count = var.enable_ses ? 1 : 0

  user = aws_iam_user.smtp_user[0].name
}

resource "aws_iam_policy" "smtp_user_policy" {
  count = var.enable_ses ? 1 : 0

  name = "${var.eks_cluster_name}-smtp-user-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-smtp-user-policy" }), var.common_tags)
}

resource "aws_iam_user_policy_attachment" "smtp_user_policy_attach" {
  count = var.enable_ses ? 1 : 0

  user       = aws_iam_user.smtp_user[0].name
  policy_arn = aws_iam_policy.smtp_user_policy[0].arn
}

output "radar_base_smtp_username" {
  value = var.enable_ses ? aws_iam_access_key.smtp_user_key[0].id : null
}

output "radar_base_smtp_password" {
  value     = var.enable_ses ? aws_iam_access_key.smtp_user_key[0].ses_smtp_password_v4 : null
  sensitive = true
}

output "radar_base_smtp_host" {
  value = var.enable_ses ? "email-smtp.${var.AWS_REGION}.amazonaws.com" : null
}

output "radar_base_smtp_port" {
  value = var.enable_ses ? 587 : null
}

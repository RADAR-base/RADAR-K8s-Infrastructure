resource "aws_ses_domain_identity" "smtp_identity" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "smtp_dkim" {
  domain = aws_ses_domain_identity.smtp_identity.domain
}

resource "aws_route53_record" "smtp_dkim_record" {
  count   = 3
  zone_id = aws_route53_zone.primary.id
  name    = "${aws_ses_domain_dkim.smtp_dkim.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.smtp_dkim.dkim_tokens[count.index]}.dkim.amazonses.com"]

  depends_on = [aws_route53_zone.primary]
}

resource "aws_ses_domain_mail_from" "smtp_mail_from" {
  domain           = aws_ses_domain_identity.smtp_identity.domain
  mail_from_domain = "info.${var.environment}.${aws_ses_domain_identity.smtp_identity.domain}"
}

resource "aws_route53_record" "smtp_mail_from_mx" {
  zone_id = aws_route53_zone.primary.id
  name    = aws_ses_domain_mail_from.smtp_mail_from.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.AWS_REGION}.amazonses.com"]

  depends_on = [aws_route53_zone.primary]
}

resource "aws_route53_record" "smtp_mail_from_txt" {
  zone_id = aws_route53_zone.primary.id
  name    = aws_ses_domain_mail_from.smtp_mail_from.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]

  depends_on = [aws_route53_zone.primary]
}

resource "aws_iam_user" "smtp_user" {
  name = "${var.eks_cluster_name}-smtp-user"
  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-smtp-user" }), var.common_tags)
}

resource "aws_iam_access_key" "smtp_user_key" {
  user = aws_iam_user.smtp_user.name
}

resource "aws_iam_policy" "smtp_user_policy" {
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
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.smtp_user_policy.arn
}

output "radar_base_smtp_username" {
  value = aws_iam_access_key.smtp_user_key.id
}

output "radar_base_smtp_password" {
  value     = aws_iam_access_key.smtp_user_key.ses_smtp_password_v4
  sensitive = true
}

output "radar_base_smtp_host" {
  value = "email-smtp.${var.AWS_REGION}.amazonaws.com"
}

output "radar_base_smtp_port" {
  value = 587
}
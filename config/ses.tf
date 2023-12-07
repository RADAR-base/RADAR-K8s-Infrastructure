resource "aws_ses_domain_identity" "smtp_identity" {
  count = var.enable_ses ? 1 : 0

  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "smtp_dkim" {
  count = var.enable_ses ? 1 : 0

  domain = aws_ses_domain_identity.smtp_identity[0].domain
}

resource "aws_route53_record" "smtp_dkim_record" {
  count   = var.enable_route53 && var.enable_ses ? 3 : 0
  zone_id = aws_route53_zone.primary[0].id
  name    = "${aws_ses_domain_dkim.smtp_dkim[0].dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.smtp_dkim[0].dkim_tokens[count.index]}.dkim.amazonses.com"]

  depends_on = [aws_route53_zone.primary[0]]
}

resource "aws_ses_domain_mail_from" "smtp_mail_from" {
  count = var.enable_ses ? 1 : 0

  domain           = aws_ses_domain_identity.smtp_identity[0].domain
  mail_from_domain = "info.${var.environment}.${aws_ses_domain_identity.smtp_identity[0].domain}"
}

resource "aws_route53_record" "smtp_mail_from_mx" {
  count   = var.enable_route53 && var.enable_ses ? 1 : 0
  zone_id = aws_route53_zone.primary[0].id
  name    = aws_ses_domain_mail_from.smtp_mail_from[0].mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.AWS_REGION}.amazonses.com"]

  depends_on = [aws_route53_zone.primary[0]]
}

resource "aws_route53_record" "smtp_mail_from_txt" {
  count   = var.enable_route53 && var.enable_ses ? 1 : 0
  zone_id = aws_route53_zone.primary[0].id
  name    = aws_ses_domain_mail_from.smtp_mail_from[0].mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]

  depends_on = [aws_route53_zone.primary[0]]
}

resource "aws_iam_user" "smtp_user" {
  count = var.enable_ses ? 1 : 0

  name = "${var.environment}-radar-base-smtp-user"
  tags = merge(tomap({ "Name" : "radar-base-smtp-user" }), var.common_tags)
}

resource "aws_iam_access_key" "smtp_user_key" {
  count = var.enable_ses ? 1 : 0

  user = aws_iam_user.smtp_user[0].name
}

resource "aws_iam_policy" "smtp_user_policy" {
  count = var.enable_ses ? 1 : 0

  name = "${var.environment}-radar-base-smtp-user-policy"

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
  value = "email-smtp.${var.AWS_REGION}.amazonaws.com"
}

output "radar_base_smtp_port" {
  value = 587
}
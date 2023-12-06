resource "aws_route53_zone" "primary" {
  count = var.enable_route53 ? 1 : 0

  name = var.domain_name
  tags = merge(tomap({ "Name" : "radar-base-primary-zone" }), var.common_tags)
}

resource "aws_route53_record" "main" {
  count = var.enable_route53 && var.enable_eip ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "${var.environment}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_eip.cluster_loadbalancer_eip[0].public_dns]
}

resource "aws_route53_record" "alertmanager" {
  count = var.enable_route53 ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "alertmanager.${var.environment}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.environment}.${var.domain_name}"]
}

resource "aws_route53_record" "dashboard" {
  count = var.enable_route53 ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "dashboard.${var.environment}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.environment}.${var.domain_name}"]
}

resource "aws_route53_record" "grafana" {
  count = var.enable_route53 ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "grafana.${var.environment}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.environment}.${var.domain_name}"]
}

resource "aws_route53_record" "graylog" {
  count = var.enable_route53 ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "graylog.${var.environment}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.environment}.${var.domain_name}"]
}

resource "aws_route53_record" "prometheus" {
  count = var.enable_route53 ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "prometheus.${var.environment}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.environment}.${var.domain_name}"]
}

resource "aws_route53_record" "s3" {
  count = var.enable_route53 ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "s3.${var.environment}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.environment}.${var.domain_name}"]
}

module "external_dns_irsa" {
  count = var.enable_route53 ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "${var.environment}-radar-base-external-dns-irsa"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${aws_route53_zone.primary[0].id}"]

  oidc_providers = {
    ex = {
      provider_arn               = join("", ["arn:aws:iam::", local.aws_account, ":oidc-provider/", local.oidc_issuer])
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = merge(tomap({ "Name" : "radar-base-external-dns-irsa" }), var.common_tags)
}

module "cert_manager_irsa" {
  count = var.enable_route53 ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "${var.environment}-radar-base-cert-manager-irsa"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${aws_route53_zone.primary[0].id}"]

  oidc_providers = {
    main = {
      provider_arn               = join("", ["arn:aws:iam::", local.aws_account, ":oidc-provider/", local.oidc_issuer])
      namespace_service_accounts = ["kube-system:cert-manager"]
    }
  }

  tags = merge(tomap({ "Name" : "radar-base-cert-manager-irsa" }), var.common_tags)
}

output "radar_base_route53_hosted_zone_id" {
  value = aws_route53_zone.primary != [] ? aws_route53_zone.primary[0].zone_id : ""
}

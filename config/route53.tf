locals {
  domain_name = length(var.domain_name) == 0 ? null : keys(var.domain_name)[0]
}

import {
  for_each = var.domain_name
  to       = aws_route53_zone.primary[0]
  id       = each.value
}

resource "aws_route53_zone" "primary" {
  count = var.enable_route53 && length(var.domain_name) == 1 ? 1 : 0
  name  = local.domain_name
  tags  = merge(tomap({ "Name" : "${var.eks_cluster_name}-primary-zone" }), var.common_tags)
}

resource "aws_route53_record" "main" {
  count = var.enable_route53 && length(var.domain_name) == 1 && var.enable_eip ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "${var.environment}.${local.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_eip.cluster_loadbalancer_eip[0].public_dns]
}

resource "aws_route53_record" "this" {
  for_each = toset([for prefix in local.cname_prefixes : prefix if var.enable_route53 && length(var.domain_name) == 1])

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "${each.value}.${var.environment}.${local.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.environment}.${local.domain_name}"]
}

module "external_dns_irsa" {
  count = var.enable_route53 && length(var.domain_name) == 1 ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "${var.eks_cluster_name}-external-dns-irsa"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${aws_route53_zone.primary[0].zone_id}"]

  oidc_providers = {
    ex = {
      provider_arn               = join("", ["arn:aws:iam::", local.aws_account, ":oidc-provider/", local.oidc_issuer])
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-external-dns-irsa" }), var.common_tags)
}

module "cert_manager_irsa" {
  count = var.enable_route53 && length(var.domain_name) == 1 ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "${var.eks_cluster_name}-cert-manager-irsa"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${aws_route53_zone.primary[0].zone_id}"]

  oidc_providers = {
    main = {
      provider_arn               = join("", ["arn:aws:iam::", local.aws_account, ":oidc-provider/", local.oidc_issuer])
      namespace_service_accounts = ["kube-system:cert-manager"]
    }
  }

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-cert-manager-irsa" }), var.common_tags)
}

output "radar_base_route53_hosted_zone_id" {
  value = var.enable_route53 && length(var.domain_name) == 1 ? aws_route53_zone.primary[0].zone_id : null
}

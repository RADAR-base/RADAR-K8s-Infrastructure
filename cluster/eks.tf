module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${var.environment}-radar-base-vpc-cni-irsa"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = merge(tomap({ "Name" : "radar-base-vpc-cni-irsa" }), var.common_tags)
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "radar-base-ebs-csi-irsa"
  attach_ebs_csi_policy = true


  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = merge(tomap({ "Name" : "radar-base-ebs-csi-irsa" }), var.common_tags)
}

module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "radar-base-external-dns-irsa"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${aws_route53_zone.primary.id}"]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = merge(tomap({ "Name" : "radar-base-external-dns-irsa" }), var.common_tags)
}

module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "${var.environment}-radar-base-cert-manager-irsa"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${aws_route53_zone.primary.id}"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cert-manager"]
    }
  }

  tags = merge(tomap({ "Name" : "radar-base-cert-manager-irsa" }), var.common_tags)
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.AWS_REGION]
    command     = "aws"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.13.1"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      addon_version     = var.eks_addon_version.coredns
      resolve_conflicts = "OVERWRITE"
      configuration_values = jsonencode({
        tolerations : [
          {
            key : "dmz-pod",
            operator : "Equal",
            value : "false",
            effect : "NoExecute"
          }
        ],
        nodeSelector : {
          role : "dmz-1"
        }
      })
    }
    kube-proxy = {
      addon_version     = var.eks_addon_version.kube_proxy
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version            = var.eks_addon_version.vpc_cni
      resolve_conflicts        = "OVERWRITE"
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        env : {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION : "true"
          WARM_PREFIX_TARGET : "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      addon_version            = var.eks_addon_version.ebs_csi_driver
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  enable_irsa = true

  eks_managed_node_group_defaults = {
    disk_size = 50
  }

  eks_managed_node_groups = {
    dmz = {
      desired_size = var.dmz_node_size["desired"]
      min_size     = var.dmz_node_size["min"]
      max_size     = var.dmz_node_size["max"]

      pre_bootstrap_user_data = <<-EOT
        cd /tmp
        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
        sudo systemctl enable amazon-ssm-agent
        sudo systemctl start amazon-ssm-agent
      EOT

      labels = {
        role = "dmz-1"
      }

      # Do we need this in the general template?
      taints = [{
        key    = "dmz-pod"
        value  = "false"
        effect = "NO_EXECUTE"
      }]

      instance_types = var.instance_types
      capacity_type  = var.instance_capacity_type
      subnet_ids     = [module.vpc.public_subnets[0]]

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }

    worker = {
      desired_size = var.worker_node_size["desired"]
      min_size     = var.worker_node_size["min"]
      max_size     = var.worker_node_size["max"]

      pre_bootstrap_user_data = <<-EOT
        cd /tmp
        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
        sudo systemctl enable amazon-ssm-agent
        sudo systemctl start amazon-ssm-agent
      EOT

      labels = {
        role = "worker"
      }

      instance_types = var.instance_types
      capacity_type  = var.instance_capacity_type
      subnet_ids     = [module.vpc.private_subnets[0]] # Single AZ due to EBS mounting limit

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        S3Access                     = aws_iam_policy.s3_access.arn
        ECRAccess                    = aws_iam_policy.ecr_access.arn
        ECRPullThroughCache          = aws_iam_policy.ecr_pull_through_cache.arn
      }
    }
  }

  node_security_group_additional_rules = {
    node_to_node = {
      description              = "This security group is for allowing communication between all nodes in the cluster (all ports)"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      type                     = "ingress"
      source_security_group_id = module.eks.node_security_group_id
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" : var.eks_cluster_name
  }

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = module.eks_admins_iam_role.iam_role_name
      groups   = ["system:masters"]
    },
  ]

  tags = merge(tomap({ "Name" : var.eks_cluster_name }), var.common_tags)

}

output "radar_base_eks_cluster_name" {
  value = module.eks.cluster_name
}

output "radar_base_eks_cluser_endpoint" {
  value = module.eks.cluster_endpoint
}

output "radar_base_eks_dmz_node_group_name" {
  value = element(split(":", module.eks.eks_managed_node_groups.dmz.node_group_id), 1)
}

output "radar_base_eks_worker_node_group_name" {
  value = element(split(":", module.eks.eks_managed_node_groups.worker.node_group_id), 1)
}

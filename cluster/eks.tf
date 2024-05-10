module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${var.eks_cluster_name}-vpc-cni-irsa"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-vpc-cni-irsa" }), var.common_tags)
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${var.eks_cluster_name}-ebs-csi-irsa"
  attach_ebs_csi_policy = true


  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-ebs-csi-irsa" }), var.common_tags)
}

locals {
  dmz_node_group = {
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

      taints = [{
        key      = "dmz-pod"
        operator = "Equal"
        value    = "yes"
        effect   = "NO_EXECUTE"
      }]

      instance_types = var.instance_types
      capacity_type  = var.instance_capacity_type
      subnet_ids     = [module.vpc.public_subnets[0]]

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  worker_node_group = {
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
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.13.1"

  cluster_name    = var.eks_cluster_name
  cluster_version = local.eks_core_versions[var.eks_kubernetes_version].cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      addon_version               = local.eks_core_versions[var.eks_kubernetes_version].cluster_addons.coredns
      resolve_conflicts_on_create = "OVERWRITE"
      configuration_values = jsonencode({
        tolerations : var.create_dmz_node_group ? [
          {
            key : "dmz-pod",
            operator : "Equal",
            value : "yes",
            effect : "NoExecute"
          }
        ] : [],
        nodeSelector : var.create_dmz_node_group ? {
          role : "dmz-1"
        } : {},
        affinity : {
          podAntiAffinity : {
            requiredDuringSchedulingIgnoredDuringExecution : [{
              labelSelector : {
                matchExpressions : [{
                  key : "k8s-app"
                  operator : "In"
                  values : ["kube-dns"]
                }]
              },
              topologyKey : "kubernetes.io/hostname"
            }]
          }
        }
      })
    }
    kube-proxy = {
      addon_version               = local.eks_core_versions[var.eks_kubernetes_version].cluster_addons.kube_proxy
      resolve_conflicts_on_create = "OVERWRITE"
    }
    vpc-cni = {
      addon_version               = local.eks_core_versions[var.eks_kubernetes_version].cluster_addons.vpc_cni
      resolve_conflicts_on_create = "OVERWRITE"
      before_compute              = true
      service_account_role_arn    = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        env : {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION : "true"
          WARM_PREFIX_TARGET : "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      addon_version               = local.eks_core_versions[var.eks_kubernetes_version].cluster_addons.ebs_csi_driver
      resolve_conflicts_on_create = "OVERWRITE"
      service_account_role_arn    = module.ebs_csi_irsa.iam_role_arn
      configuration_values = jsonencode({
        sidecars : {
          snapshotter : {
            forceEnable : false
          }
        },
        controller : {
          volumeModificationFeature : {
            enabled : true
          }
        }
      })
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  enable_irsa = true

  eks_managed_node_group_defaults = {
    disk_size = 50
  }

  eks_managed_node_groups = merge(local.worker_node_group, var.create_dmz_node_group ? local.dmz_node_group : {})

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

  kms_key_administrators = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
  kms_key_users = [
    module.eks_admins_iam_role.iam_role_arn,
  ]

  tags = merge(tomap({ "Name" : var.eks_cluster_name }), var.common_tags)
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_access" {
  security_group_id            = aws_security_group.vpc_endpoint.id
  ip_protocol                  = "-1"
  referenced_security_group_id = module.eks.node_security_group_id

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-vpc-endpoints-access" }), var.common_tags)

  depends_on = [
    aws_security_group.vpc_endpoint
  ]
}
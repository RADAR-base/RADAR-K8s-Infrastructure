module "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/karpenter?ref=37e3348dffe06ea4b9adf9b54512e4efdb46f425" # commit hash of version 20.36.0

  cluster_name          = data.aws_eks_cluster.main.id
  enable_v1_permissions = true

  create_instance_profile = false
  create_node_iam_role    = false
  create_access_entry     = false
  node_iam_role_arn       = local.worker_node_group.node_role_arn

  enable_irsa            = true
  irsa_oidc_provider_arn = join("", ["arn:aws:iam::", local.aws_account, ":oidc-provider/", local.oidc_issuer])

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-karpenter" }), var.common_tags)
}

locals {
  common_settings = [
    {
      name  = "settings.clusterName"
      value = data.aws_eks_cluster.main.id
    },
    {
      name  = "settings.clusterEndpoint"
      value = data.aws_eks_cluster.main.endpoint
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = length(module.karpenter) > 0 ? module.karpenter[0].iam_role_arn : null
    },
    {
      name  = "settings.interruptionQueue"
      value = length(module.karpenter) > 0 ? module.karpenter[0].queue_name : null
    },
    {
      name  = "webhook.enabled"
      value = "false"
    },
    {
      name  = "controller.resources.requests.cpu"
      value = "1"
    },
    {
      name  = "controller.resources.requests.memory"
      value = "1Gi"
    },
    {
      name  = "controller.resources.limits.cpu"
      value = "1"
    },
    {
      name  = "controller.resources.limits.memory"
      value = "1Gi"
    },
    {
      name  = "replicas"
      value = 1
    },
  ]

  tolerations_settings = [
    {
      name  = "tolerations[0].key"
      value = "dmz-pod"
    },
    {
      name  = "tolerations[0].value"
      value = "yes"
    },
    {
      name  = "tolerations[0].operator"
      value = "Equal"
    },
    {
      name  = "tolerations[0].effect"
      value = "NoExecute"
    },
  ]
}

resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version



  dynamic "set" {
    for_each = var.with_dmz_pods ? concat(local.common_settings, local.tolerations_settings) : local.common_settings

    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  depends_on = [
    kubectl_manifest.karpenter_node_pool,
    kubectl_manifest.karpenter_node_class,
  ]
}

resource "helm_release" "karpenter_crd" {
  count = var.enable_karpenter ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter-crd"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = var.karpenter_version

  depends_on = [
    module.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  for_each = var.enable_karpenter ? var.karpenter_node_pools : {}

  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = each.key
    }
    spec = {
      template = {
        spec = {
          requirements = concat(
            [
              {
                key      = "kubernetes.io/arch"
                operator = "In"
                values   = each.value.architecture
              },
              {
                key      = "kubernetes.io/os"
                operator = "In"
                values   = each.value.os
              },
              {
                key      = "karpenter.sh/capacity-type"
                operator = "In"
                values   = each.value.instance_capacity_type
              },
              {
                key      = "karpenter.k8s.aws/instance-category"
                operator = "In"
                values   = each.value.instance_category
              },
              {
                key      = "karpenter.k8s.aws/instance-cpu"
                operator = "In"
                values   = each.value.instance_cpu
              },
              {
                key      = "topology.kubernetes.io/zone"
                operator = "In"
                values   = local.worker_node_zones
              },
            ],
          )
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
          expireAfter = "720h"
        }
      }
      limits = {
        cpu    = "32"
        memory = "128Gi"
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "1m"
      }
    }
  })

  depends_on = [
    module.karpenter,
    helm_release.karpenter_crd,
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  count = var.enable_karpenter ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      role = regex("[^/]+$", module.karpenter[0].node_iam_role_arn)
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize = "40Gi"
            volumeType = "gp3"
          }
          deleteOnTermination = true
        },
      ]
      amiSelectorTerms = [{
        alias = var.karpenter_ami_selector_alias
      }]
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = data.aws_eks_cluster.main.id
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = data.aws_eks_cluster.main.id
          }
        }
      ]
      tags = {
        "karpenter.sh/discovery" = data.aws_eks_cluster.main.id
      }
    }
  })

  depends_on = [
    module.karpenter,
    helm_release.karpenter_crd,
  ]
}

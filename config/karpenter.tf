module "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/karpenter?ref=2cb1fac31b0fc2dd6a236b0c0678df75819c5a3b" # commit hash of version 19.21.0

  cluster_name = data.aws_eks_cluster.main.id

  irsa_oidc_provider_arn          = join("", ["arn:aws:iam::", local.aws_account, ":oidc-provider/", local.oidc_issuer])
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_iam_role = false
  iam_role_arn    = local.worker_node_group.node_role_arn

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-karpenter" }), var.common_tags)
}

locals {
  common_settings = [
    {
      name  = "settings.aws.clusterName"
      value = data.aws_eks_cluster.main.id
    },
    {
      name  = "settings.aws.clusterEndpoint"
      value = data.aws_eks_cluster.main.endpoint
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = length(module.karpenter) > 0 ? module.karpenter[0].irsa_arn : null
    },
    {
      name  = "settings.aws.defaultInstanceProfile"
      value = length(module.karpenter) > 0 ? module.karpenter[0].instance_profile_name : null
    },
    {
      name  = "settings.aws.interruptionQueueName"
      value = length(module.karpenter) > 0 ? module.karpenter[0].queue_name : null
    },
    {
      name  = "replicas"
      value = 2
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
}

resource "kubectl_manifest" "karpenter_provisioner" {
  count = var.enable_karpenter ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values:
            - amd64
        - key: kubernetes.io/os
          operator: In
          values:
            - linux
        - key: karpenter.sh/capacity-type
          operator: In
          values:
            - "${lower(var.instance_capacity_type)}"
        - key: topology.kubernetes.io/zone
          operator: In
          values:
            - "${var.AWS_REGION}a"
            # - "${var.AWS_REGION}b"
            # - "${var.AWS_REGION}c"
      ttlSecondsAfterEmpty: 30
      limits:
        resources:
          cpu: 64
          memory: 256Gi
      providerRef:
        name: default
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_template" {
  count = var.enable_karpenter ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${data.aws_eks_cluster.main.id}
      securityGroupSelector:
        karpenter.sh/discovery: ${data.aws_eks_cluster.main.id}
      tags:
        karpenter.sh/discovery: ${data.aws_eks_cluster.main.id}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

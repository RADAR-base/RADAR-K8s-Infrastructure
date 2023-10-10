provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

module "karpenter_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                          = "karpenter-controller-${var.environment}-radar-base-cluster"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name = module.eks.cluster_name
  karpenter_controller_ssm_parameter_arns = [
    "arn:aws:ssm:*:*:parameter/aws/service/*"
  ]
  karpenter_controller_node_iam_role_arns = [
    module.eks.eks_managed_node_groups["worker"].iam_role_arn
  ]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${var.environment}-radar-base-cluster"
  role = module.eks.eks_managed_node_groups["worker"].iam_role_name
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "0.8.2"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa_role.iam_role_arn
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }
}

# Workaround - https://github.com/hashicorp/terraform-provider-kubernetes/issues/1380#issuecomment-967022975
resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
---
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
        - spot
    - key: topology.kubernetes.io/zone
      operator: In
      values:
        - eu-west-2a
  ttlSecondsAfterEmpty: 30
  providerRef:
    name: default
  limits:
    resources:
      cpu: 64
      memory: 256Gi
  consolidation:
    enabled: true
  provider:
    subnetSelector:
      karpenter.sh/discovery: ${var.environment}-radar-base-cluster
    securityGroupSelector:
      karpenter.sh/discovery: ${var.environment}-radar-base-cluster
    tags:
      karpenter.sh/discovery: ${var.environment}-radar-base-cluster
  # nodeSelector:
  #   role: dmz-1
  # tolerations:
  #   - key: "dmz-pod"
  #     operator: "Equal"
  #     value: "false"
  #     effect: "NoExecute"
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
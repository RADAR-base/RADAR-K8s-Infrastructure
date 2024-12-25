data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.eks_cluster_name}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${var.eks_cluster_name}-vpc"]
  }
  filter {
    name   = "tag:subnet-type"
    values = ["private"]
  }
}

data "aws_security_group" "node" {
  filter {
    name   = "tag:Name"
    values = ["${var.eks_cluster_name}-node"]
  }
}

data "aws_security_group" "vpc_default" {
  filter {
    name   = "tag:Name"
    values = ["${var.eks_cluster_name}-vpc-default-sg"]
  }
}

data "aws_eks_cluster" "main" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = var.eks_cluster_name
}

data "aws_eks_node_groups" "main" {
  cluster_name = var.eks_cluster_name
}

data "aws_eks_node_group" "main" {
  for_each = data.aws_eks_node_groups.main.names

  cluster_name    = var.eks_cluster_name
  node_group_name = each.value
}

locals {
  aws_account = element(split(":", data.aws_eks_cluster.main.arn), 4)
  oidc_issuer = element(split("//", data.aws_eks_cluster.main.identity[0].oidc[0].issuer), 1)

  s3_bucket_names = {
    intermediate_output_storage = "${var.eks_cluster_name}-intermediate-output-storage"
    output_storage              = "${var.eks_cluster_name}-output-storage"
    velero_backups              = "${var.eks_cluster_name}-velero-backups"
  }

  cname_prefixes = [
    "alertmanager",
    "dashboard",
    "grafana",
    "graylog",
    "prometheus",
    "s3",
  ]

  worker_node_group = [
    for name in keys(data.aws_eks_node_group.main) : data.aws_eks_node_group.main[name] if startswith(name, "worker-${var.eks_cluster_name}-")
  ][0] # There is only one worker node group so be this

}

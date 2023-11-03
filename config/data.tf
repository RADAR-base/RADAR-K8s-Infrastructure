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
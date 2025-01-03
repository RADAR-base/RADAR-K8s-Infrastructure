module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.eks_cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs = [
    "${var.AWS_REGION}a",
    "${var.AWS_REGION}b",
    "${var.AWS_REGION}c",
  ]

  private_subnets = var.vpc_private_subnet_cidr
  public_subnets  = var.vpc_public_subnet_cidr

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "subnet-type"            = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "subnet-type"                     = "private"
    "karpenter.sh/discovery"          = var.eks_cluster_name
  }

  enable_nat_gateway      = true
  single_nat_gateway      = true
  one_nat_gateway_per_az  = false
  map_public_ip_on_launch = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  default_security_group_tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-vpc-default-sg" }), var.common_tags)
  tags                        = merge(tomap({ "Name" : "${var.eks_cluster_name}-vpc" }), var.common_tags)
}

resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "${var.eks_cluster_name}-vpc-endpoint-sg-"
  vpc_id      = module.vpc.vpc_id

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-vpc-endpoint-sg" }), var.common_tags)
}

resource "aws_security_group_rule" "vpc_endpoint_egress" {
  security_group_id = aws_security_group.vpc_endpoint.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = var.vpc_private_subnet_cidr
}

resource "aws_security_group_rule" "vpc_endpoint_self_ingress" {
  security_group_id        = aws_security_group.vpc_endpoint.id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.vpc_endpoint.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.AWS_REGION}.s3"
  vpc_endpoint_type = "Gateway"

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-s3-vpc-endpoint" }), var.common_tags)
}

resource "aws_vpc_endpoint" "ecr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.AWS_REGION}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = false

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-ecr-vpc-endpoint" }), var.common_tags)
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.AWS_REGION}.sts"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = false

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-sts-vpc-endpoint" }), var.common_tags)
}

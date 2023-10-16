module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "${var.environment}-${var.eks_cluster_base_name}-vpc"
  cidr = "10.0.0.0/16"

  azs = [
    "${var.AWS_REGION}a",
    "${var.AWS_REGION}b",
    "${var.AWS_REGION}c",
  ]
  private_subnets = [
    "10.0.0.0/19",
    "10.0.32.0/19",
    "10.0.64.0/19",
  ]
  public_subnets = [
    "10.0.96.0/19",
    "10.0.128.0/19",
    "10.0.160.0/19",
  ]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "subnet-type"            = "public"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "subnet-type"                     = "private"
    "karpenter.sh/discovery"          = "${var.environment}-${var.eks_cluster_base_name}"
  }

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(tomap({ "Name" : "${var.environment}-${var.eks_cluster_base_name}-vpc" }), var.common_tags)
}

output "radar_base_vpc_public_subnets" {
  value = module.vpc.public_subnets
}

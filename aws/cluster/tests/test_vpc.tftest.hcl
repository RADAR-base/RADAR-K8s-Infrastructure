mock_provider "aws" {
  source = "./tests/mocks"
}
mock_provider "kubectl" {}
mock_provider "kubernetes" {}

variables {
  eks_cluster_name      = "radar-base-test"
  common_tags = {
    Project     = "radar-base"
    Environment = "dev"
  }

  AWS_REGION            = "eu-west-2"
  AWS_ACCESS_KEY_ID     = "test"
  AWS_SECRET_ACCESS_KEY = "test"
  AWS_SESSION_TOKEN     = ""
  AWS_PROFILE           = "default"
}

run "vpc_endpoints_target_the_regional_service_names" {
  command = plan

  assert {
    condition = alltrue([
      aws_vpc_endpoint.s3.service_name == "com.amazonaws.eu-west-2.s3",
      aws_vpc_endpoint.ecr.service_name == "com.amazonaws.eu-west-2.ecr.dkr",
      aws_vpc_endpoint.sts.service_name == "com.amazonaws.eu-west-2.sts",
    ])
    error_message = "Each endpoint should target its regional service name"
  }

  assert {
    condition = alltrue([
      aws_vpc_endpoint.s3.vpc_endpoint_type == "Gateway",
      aws_vpc_endpoint.ecr.vpc_endpoint_type == "Interface",
      aws_vpc_endpoint.sts.vpc_endpoint_type == "Interface",
    ])
    error_message = "S3 should use a Gateway endpoint while ECR and STS use Interface endpoints"
  }

  assert {
    condition = alltrue([
      aws_vpc_endpoint.ecr.private_dns_enabled,
      aws_vpc_endpoint.sts.private_dns_enabled,
    ])
    error_message = "The ECR and STS interface endpoints should have private DNS enabled"
  }

  assert {
    condition = alltrue([
      aws_vpc_endpoint.s3.tags["Name"] == "radar-base-test-s3-vpc-endpoint",
      aws_vpc_endpoint.ecr.tags["Name"] == "radar-base-test-ecr-vpc-endpoint",
      aws_vpc_endpoint.sts.tags["Name"] == "radar-base-test-sts-vpc-endpoint",
      aws_vpc_endpoint.s3.tags["Project"] == "radar-base",
      aws_vpc_endpoint.ecr.tags["Project"] == "radar-base",
      aws_vpc_endpoint.sts.tags["Project"] == "radar-base",
    ])
    error_message = "Each endpoint should be tagged with its name and the common tags"
  }
}

run "endpoint_service_names_follow_the_aws_region_variable" {
  command = plan

  variables {
    AWS_REGION = "eu-west-2"
  }

  assert {
    condition = alltrue([
      aws_vpc_endpoint.s3.service_name == "com.amazonaws.eu-west-2.s3",
      aws_vpc_endpoint.ecr.service_name == "com.amazonaws.eu-west-2.ecr.dkr",
      aws_vpc_endpoint.sts.service_name == "com.amazonaws.eu-west-2.sts",
    ])
    error_message = "Endpoint service names should be built from var.AWS_REGION"
  }
}

run "vpc_creates_one_subnet_and_route_table_per_availability_zone" {
  command = plan

  assert {
    condition = alltrue([
      length(module.vpc.private_subnets) == 3,
      length(module.vpc.public_subnets) == 3,
    ])
    error_message = "The VPC should span the three AZs for both subnet tiers"
  }

  assert {
    condition = alltrue([
      length(module.vpc.private_route_table_ids) == 1,
      length(module.vpc.public_route_table_ids) == 1,
    ])
    error_message = "A single AZ NAT gateway per tier should mean exactly one private and one public route table"
  }
}

run "vpc_endpoint_security_group_allows_the_private_cidrs" {
  command = plan

  assert {
    condition     = aws_security_group.vpc_endpoint.name_prefix == "radar-base-test-vpc-endpoint-sg-"
    error_message = "The endpoint security group should use a name prefix: ${var.eks_cluster_name}"
  }

  assert {
    condition     = toset(aws_security_group_rule.vpc_endpoint_egress.cidr_blocks) == toset(var.vpc_private_subnet_cidr)
    error_message = "Egress should be limited to the private subnet CIDRs"
  }

  assert {
    condition = alltrue([
      aws_security_group_rule.vpc_endpoint_egress.type == "egress",
      aws_security_group_rule.vpc_endpoint_egress.protocol == "-1",
      aws_security_group_rule.vpc_endpoint_egress.from_port == 0,
      aws_security_group_rule.vpc_endpoint_egress.to_port == 0,
    ])
    error_message = "Egress should be unrestricted within the private CIDRs"
  }

  assert {
    condition = alltrue([
      aws_security_group_rule.vpc_endpoint_self_ingress.type == "ingress",
      aws_security_group_rule.vpc_endpoint_self_ingress.protocol == "-1",
      aws_security_group_rule.vpc_endpoint_self_ingress.from_port == 0,
      aws_security_group_rule.vpc_endpoint_self_ingress.to_port == 0,
    ])
    error_message = "Self-ingress should be unrestricted for the health checks"
  }
}

run "eks_nodes_are_allowed_to_reach_the_vpc_endpoints" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.vpc_endpoints_access.ip_protocol == "-1"
    error_message = "The endpoint ingress rule should allow all protocols"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.vpc_endpoints_access.tags["Name"] == "${var.eks_cluster_name}-vpc-endpoints-access"
    error_message = "The ingress rule should be tagged with the cluster name"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.vpc_endpoints_access.tags["Project"] == var.common_tags["Project"]
    error_message = "The ingress rule should also carry the common tags"
  }
}

run "vpc_network_layout_follows_the_variables" {
  command = plan

  assert {
    condition = alltrue([
      length(var.vpc_private_subnet_cidr) == 3,
      length(var.vpc_public_subnet_cidr) == 3,
      var.vpc_cidr == "10.0.0.0/16",
    ])
    error_message = "The default layout should be a /16 VPC with three private and three public subnets"
  }

  assert {
    condition     = length(aws_vpc_endpoint.ecr.subnet_ids) == 1
    error_message = "The ECR endpoint should be pinned to a first private subnet due to single AZ"
  }

  assert {
    condition     = length(aws_vpc_endpoint.sts.subnet_ids) == 1
    error_message = "The STS endpoint should be pinned to a first private subnet due to single AZ"
  }

  assert {
    condition     = length(aws_vpc_endpoint.ecr.security_group_ids) == 1
    error_message = "Each interface endpoint should reference only the endpoint security group"
  }
}

mock_provider "aws" {
  source = "./tests/mocks"
}

mock_provider "archive" {}
mock_provider "helm" {}
mock_provider "kubectl" {}
mock_provider "kubernetes" {}
mock_provider "random" {}

variables {
  eks_cluster_name = "radar-base-test"
  radar_postgres_password = "test"
  docker_hub_username     = "test"
  docker_hub_access_token = "test"
  ghcr_username           = "test"
  ghcr_access_token       = "test"
  domain_name = { "radar-base.test" = "Z0123456789ABCDEFGHIJ" }
  enable_metrics          = false
  enable_karpenter        = false
  enable_msk              = false
  enable_rds              = false
  enable_route53          = false
  enable_ses              = false
  enable_s3               = false
  enable_eip              = false
  enable_ecr_ptc          = false
  with_dmz_pods           = false
  ses_bounce_destinations = []

  AWS_ACCESS_KEY_ID       = "test"
  AWS_SECRET_ACCESS_KEY   = "test"
}

run "rejects_multiple_domain_pairs" {
  command = plan

  variables {
    domain_name = {
      "radar-base.test" = "Z0123456789ABCDEFGHIJ"
      "example.test"    = "Z9876543210ZYXWVUTSRQ"
    }
  }

  expect_failures = [var.domain_name]
}

run "rejects_rds_without_password" {
  command = plan

  variables {
    enable_rds              = true
    radar_postgres_password = ""
  }

  expect_failures = [var.enable_rds]
}

run "rejects_ecr_pull_through_cache_without_credentials" {
  command = plan

  variables {
    enable_ecr_ptc          = true
    docker_hub_username     = ""
    docker_hub_access_token = ""
  }

  expect_failures = [var.enable_ecr_ptc]
}

run "rejects_unknown_karpenter_capacity_type" {
  command = plan

  variables {
    enable_karpenter = true
    karpenter_node_pools = {
      default = {
        architecture           = ["amd64"]
        os                     = ["linux"]
        instance_capacity_type = ["unknown-capacity-type"]
        instance_category      = ["m"]
        instance_cpu           = ["2"]
      }
    }
  }

  expect_failures = [var.karpenter_node_pools]
}

run "accepts_single_domain_pair" {
  command = plan

  assert {
    condition     = length(var.domain_name) == 1
    error_message = "A single domain pair should be accepted"
  }
}

run "accepts_documented_karpenter_capacity_types" {
  command = plan

  variables {
    enable_karpenter = true
    karpenter_node_pools = {
      default = {
        architecture           = ["amd64"]
        os                     = ["linux"]
        instance_capacity_type = ["spot", "on-demand", "reserved"]
        instance_category      = ["c", "m", "r"]
        instance_cpu           = ["2", "4"]
      }
    }
  }

  assert {
    condition     = length(kubectl_manifest.karpenter_node_pool) == 1
    error_message = "The 'default' node pool should be planned when karpenter node pools are supplied"
  }
}

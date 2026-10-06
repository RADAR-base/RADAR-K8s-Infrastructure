mock_provider "aws" {
  source = "./tests/mocks"
}

mock_provider "kubectl" {}
mock_provider "kubernetes" {}

variables {
  eks_cluster_name = "radar-base-test"

  AWS_REGION            = "eu-west-2"
  AWS_ACCESS_KEY_ID     = "test"
  AWS_SECRET_ACCESS_KEY = "test"
  AWS_SESSION_TOKEN     = ""
  AWS_PROFILE           = "default"
}

run "rejects_an_empty_cluster_name" {
  command = plan

  variables {
    eks_cluster_name = ""
  }

  expect_failures = [var.eks_cluster_name]
}

run "rejects_an_unsupported_kubernetes_version" {
  command = plan

  variables {
    eks_kubernetes_version = "unsupported-version"
  }

  expect_failures = [var.eks_kubernetes_version]
}

run "rejects_an_unsupported_instance_capacity_type" {
  command = plan

  variables {
    instance_capacity_type = "unsupported-capacity-type"
  }

  expect_failures = [var.instance_capacity_type]
}

run "rejects_an_unknown_default_storage_class" {
  command = plan

  variables {
    default_storage_class = "unknown-storage-class"
  }

  expect_failures = [var.default_storage_class]
}

run "accepts_every_documented_default_storage_class" {
  command = plan

  variables {
    default_storage_class = "radar-base-ebs-sc-io1"
  }

  assert {
    condition     = kubernetes_annotations.set_default_storage_class.metadata[0].name == "radar-base-ebs-sc-io1"
    error_message = "The selected default storage class annotation should target the chosen class"
  }
}

run "accepts_documented_capacity_types" {
  command = plan

  variables {
    instance_capacity_type = "ON_DEMAND"
  }

  assert {
    condition     = length(module.eks.eks_managed_node_groups) == 1
    error_message = "ON_DEMAND should be accepted and the cluster should still plan"
  }
}

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
  enable_karpenter        = true
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

  karpenter_node_pools = {
    default = {
      architecture           = ["amd64"]
      os                     = ["linux"]
      instance_capacity_type = ["on-demand"]
      instance_category      = ["c", "m"]
      instance_cpu           = ["2", "4"]
    }
    spot = {
      architecture           = ["amd64", "arm64"]
      os                     = ["linux"]
      instance_capacity_type = ["spot"]
      instance_category      = ["c", "m", "r"]
      instance_cpu           = ["2", "4", "8"]
    }
  }
}

run "karpenter_plans_the_full_graph" {
  command = plan

  assert {
    condition = alltrue([
      length(module.karpenter) == 1,
      length(helm_release.karpenter) == 1,
      length(helm_release.karpenter_crd) == 1,
      length(kubectl_manifest.karpenter_node_class) == 1,
      length(kubectl_manifest.karpenter_node_pool) == 2,
      length(aws_iam_role_policy.karpenter_list_instance_profiles) == 1,
    ])
    error_message = "The enable_karpenter should plan the module, both charts, one EC2NodeClass and one NodePool per configured pool"
  }

  assert {
    condition = alltrue([
      helm_release.karpenter[0].name == "karpenter",
      helm_release.karpenter[0].chart == "karpenter",
      helm_release.karpenter[0].namespace == "karpenter",
      helm_release.karpenter[0].create_namespace,
      helm_release.karpenter_crd[0].name == "karpenter-crd",
      helm_release.karpenter_crd[0].repository == "oci://public.ecr.aws/karpenter",
    ])
    error_message = "Both charts should be installed from the public ECR repository into the karpenter namespace"
  }
}

run "karpenter_reuses_the_worker_node_group_role" {
  command = plan

  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_role_policy.karpenter_list_instance_profiles[0].policy).Statement :
      statement.Action == "iam:ListInstanceProfiles" && statement.Resource == "*"
    ])
    error_message = "The inline policy should allow only iam:ListInstanceProfiles"
  }

  assert {
    condition     = aws_iam_role_policy.karpenter_list_instance_profiles[0].name == "KarpenterListInstanceProfiles"
    error_message = "The inline policy should be named KarpenterListInstanceProfiles"
  }
}

run "node_pool_requirements_cover_every_dimension" {
  command = plan

  assert {
    condition     = length(yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).spec.template.spec.requirements) == 6
    error_message = "The NodePool should declare the requirements"
  }

  assert {
    condition = alltrue([
      for requirement in yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).spec.template.spec.requirements :
      requirement.operator == "In"
    ])
    error_message = "Every requirement should use the In operator"
  }

  assert {
    condition = alltrue([
      for requirement in yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).spec.template.spec.requirements :
      requirement.values == ["eu-west-2a"] if requirement.key == "topology.kubernetes.io/zone"
    ])
    error_message = "The zone requirement should be limited to local.worker_node_zones"
  }

  assert {
    condition = alltrue([
      for requirement in yamldecode(kubectl_manifest.karpenter_node_pool["spot"].yaml_body).spec.template.spec.requirements :
      requirement.values == ["amd64", "arm64"] if requirement.key == "kubernetes.io/arch"
    ])
    error_message = "The spot pool should request both amd64 and arm64"
  }

  assert {
    condition = alltrue([
      for requirement in yamldecode(kubectl_manifest.karpenter_node_pool["spot"].yaml_body).spec.template.spec.requirements :
      requirement.values == ["spot"] if requirement.key == "karpenter.sh/capacity-type"
    ])
    error_message = "The spot pool should only request spot capacity"
  }
}

# karpenter.tf:193-208.
run "node_pool_sizing_and_disruption_defaults" {
  command = plan

  assert {
    condition = alltrue([
      yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).spec.template.spec.expireAfter == "720h",
      yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).spec.limits.cpu == "32",
      yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).spec.limits.memory == "128Gi",
      yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).spec.disruption.consolidationPolicy == "WhenEmpty",
      yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).spec.disruption.consolidateAfter == "1m",
    ])
    error_message = "NodePool expiry, limits and disruption defaults should match"
  }

  assert {
    condition = alltrue([
      yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).spec.template.spec.nodeClassRef.name == "default",
      yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).apiVersion == "karpenter.sh/v1",
      yamldecode(kubectl_manifest.karpenter_node_pool["default"].yaml_body).metadata.name == "default",
    ])
    error_message = "Each NodePool should be named after its map key and reference the default EC2NodeClass"
  }
}

run "bottlerocket_ami_adds_a_second_block_device" {
  command = plan

  variables {
    karpenter_ami_version_alias = "bottlerocket@v1.19.2-rc.1"
  }

  assert {
    condition     = length(yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings) == 2
    error_message = "A bottlerocket AMI should get two block device mappings"
  }

  assert {
    condition = alltrue([
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings[0].deviceName == "/dev/xvda",
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings[0].ebs.volumeSize == "4Gi",
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings[1].deviceName == "/dev/xvdb",
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings[1].ebs.volumeSize == "40Gi",
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings[0].ebs.volumeType == "gp3",
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings[1].ebs.deleteOnTermination,
    ])
    error_message = "Bottlerocket should reserve a 4Gi OS volume on /dev/xvda and a 40Gi data volume on /dev/xvdb"
  }
}

run "al2023_ami_uses_a_single_block_device" {
  command = plan

  variables {
    karpenter_ami_version_alias = "al2023@latest"
  }

  assert {
    condition     = length(yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings) == 1
    error_message = "A non-bottlerocket AMI should get a single block device mapping"
  }

  assert {
    condition = alltrue([
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings[0].deviceName == "/dev/xvda",
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.blockDeviceMappings[0].ebs.volumeSize == "40Gi",
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.amiSelectorTerms[0].alias == "al2023@latest",
    ])
    error_message = "AL2023 should use a single 20Gi volume on /dev/xvda and pass the alias through"
  }

  assert {
    condition = alltrue([
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.subnetSelectorTerms[0].tags["karpenter.sh/discovery"] == "radar-base-test",
      yamldecode(kubectl_manifest.karpenter_node_class[0].yaml_body).spec.securityGroupSelectorTerms[0].tags["karpenter.sh/discovery"] == "radar-base-test",
    ])
    error_message = "Subnet, security group and node tagging should all use the karpenter.sh/discovery tag"
  }
}

run "helm_settings_exclude_dmz_tolerations_by_default" {
  command = plan

  assert {
    condition     = length([for setting in helm_release.karpenter[0].set : setting.name]) == 10
    error_message = "Without with_dmz_pods the chart should receive the ten entries in local.common_settings"
  }

  assert {
    condition = alltrue([
      for setting in helm_release.karpenter[0].set :
      setting.name == "tolerations[0].key" ? false : true
    ])
    error_message = "No toleration settings should be present when with_dmz_pods is false"
  }

  assert {
    condition = contains(
      [for setting in helm_release.karpenter[0].set : setting.name],
      "settings.interruptionQueue",
    )
    error_message = "The interruption queue setting should always be present"
  }
}

run "with_dmz_pods_appends_four_toleration_settings" {
  command = plan

  variables {
    with_dmz_pods = true
  }

  assert {
    condition     = length([for setting in helm_release.karpenter[0].set : setting.name]) == 14
    error_message = "with_dmz_pods should append the four entries in local.tolerations_settings to the ten common settings"
  }

  assert {
    condition = length([
      for setting in helm_release.karpenter[0].set : setting.name
      if contains([
        "tolerations[0].key",
        "tolerations[0].value",
        "tolerations[0].operator",
        "tolerations[0].effect",
      ], setting.name)
    ]) == 4
    error_message = "The four toleration settings from local.tolerations_settings should be appended"
  }

  assert {
    condition = alltrue([
      for setting in helm_release.karpenter[0].set :
      setting.value == "dmz-pod" if setting.name == "tolerations[0].key"
    ])
    error_message = "The appended toleration should target the 'dmz-pod' key"
  }
}

run "empty_node_pools_disable_the_node_pool_manifest" {
  command = plan

  variables {
    karpenter_node_pools = {}
  }

  assert {
    condition     = length(kubectl_manifest.karpenter_node_pool) == 0
    error_message = "With no configured pools, no NodePool manifest should be planned"
  }

  assert {
    condition = alltrue([
      length(helm_release.karpenter) == 1,
      length(helm_release.karpenter_crd) == 1,
      length(kubectl_manifest.karpenter_node_class) == 1,
    ])
    error_message = "Karpenter itself should still be installed when no node pools are declared"
  }
}

run "disabling_karpenter_removes_every_karpenter_resource" {
  command = plan

  variables {
    enable_karpenter = false
  }

  assert {
    condition = alltrue([
      length(module.karpenter) == 0,
      length(helm_release.karpenter) == 0,
      length(helm_release.karpenter_crd) == 0,
      length(kubectl_manifest.karpenter_node_class) == 0,
      length(kubectl_manifest.karpenter_node_pool) == 0,
      length(aws_iam_role_policy.karpenter_list_instance_profiles) == 0,
    ])
    error_message = "Turning enable_karpenter off should remove every karpenter resource"
  }
}

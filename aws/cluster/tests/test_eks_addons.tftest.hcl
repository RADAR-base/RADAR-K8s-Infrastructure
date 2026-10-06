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

run "all_addons_are_pinned_for_kubernetes_1_35" {
  command = plan

  variables {
    eks_kubernetes_version = "1.35"
  }

  assert {
    condition     = length(module.eks.cluster_addons) == 4
    error_message = "Add-ons for coredns, kube-proxy, vpc-cni and aws-ebs-csi-driver should all be configured"
  }

  assert {
    condition = alltrue([
      module.eks.cluster_addons["coredns"].addon_version == "v1.13.2-eksbuild.3",
      module.eks.cluster_addons["kube-proxy"].addon_version == "v1.35.0-eksbuild.2",
      module.eks.cluster_addons["vpc-cni"].addon_version == "v1.21.1-eksbuild.1",
      module.eks.cluster_addons["aws-ebs-csi-driver"].addon_version == "v1.56.0-eksbuild.1",
    ])
    error_message = "The add-on versions for 1.35 do not match local.eks_core_versions[\"1.35\"]"
  }
}

run "vpc_cni_and_ebs_csi_addons_carry_their_configuration" {
  command = plan

  assert {
    condition = alltrue([
      jsondecode(module.eks.cluster_addons["vpc-cni"].configuration_values).env.ENABLE_PREFIX_DELEGATION == "true",
      jsondecode(module.eks.cluster_addons["vpc-cni"].configuration_values).env.WARM_PREFIX_TARGET == "1",
    ])
    error_message = "The VPC-CNI add-on should enable prefix delegation"
  }

  assert {
    condition = alltrue([
      jsondecode(module.eks.cluster_addons["aws-ebs-csi-driver"].configuration_values).controller.volumeModificationFeature.enabled == true,
      jsondecode(module.eks.cluster_addons["aws-ebs-csi-driver"].configuration_values).sidecars.snapshotter.forceEnable == false,
    ])
    error_message = "The EBS CSI add-on should enable volume modification"
  }
}

run "coredns_uses_pod_anti_affinity_without_a_dmz_node_group" {
  command = plan

  variables {
    create_dmz_node_group = false
  }

  assert {
    condition     = length(module.eks.eks_managed_node_groups) == 1
    error_message = "Only the worker node group should be created when 'create_dmz_node_group' is false"
  }

  assert {
    condition     = length(jsondecode(module.eks.cluster_addons["coredns"].configuration_values).affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution) == 1
    error_message = "The coredns should carry one required pod anti-affinity term"
  }

  assert {
    condition = alltrue([
      jsondecode(module.eks.cluster_addons["coredns"].configuration_values).affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey == "kubernetes.io/hostname",
      jsondecode(module.eks.cluster_addons["coredns"].configuration_values).affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchExpressions[0].key == "k8s-app",
      toset(jsondecode(module.eks.cluster_addons["coredns"].configuration_values).affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchExpressions[0].values) == toset(["kube-dns"]),
    ])
    error_message = "The anti-affinity term should spread kube-dns pods across nodes"
  }

  assert {
    condition     = length(jsondecode(module.eks.cluster_addons["coredns"].configuration_values).tolerations) == 0
    error_message = "No tolerations should be configured when there is no DMZ taint"
  }

  assert {
    condition     = length(jsondecode(module.eks.cluster_addons["coredns"].configuration_values).nodeSelector) == 0
    error_message = "No node selector should be configured when there is no DMZ node group"
  }
}

run "coredns_tolerates_the_dmz_taint_when_a_dmz_node_group_exists" {
  command = plan

  variables {
    create_dmz_node_group = true
  }

  assert {
    condition     = length(module.eks.eks_managed_node_groups) == 2
    error_message = "Both DMZ and worker node groups should be created when create_dmz_node_group is true"
  }

  assert {
    condition     = length(jsondecode(module.eks.cluster_addons["coredns"].configuration_values).tolerations) == 1
    error_message = "The coredns should tolerate the single dmz-pod taint"
  }

  assert {
    condition = alltrue([
      jsondecode(module.eks.cluster_addons["coredns"].configuration_values).tolerations[0].key == "dmz-pod",
      jsondecode(module.eks.cluster_addons["coredns"].configuration_values).tolerations[0].operator == "Equal",
      jsondecode(module.eks.cluster_addons["coredns"].configuration_values).tolerations[0].value == "yes",
      jsondecode(module.eks.cluster_addons["coredns"].configuration_values).tolerations[0].effect == "NoExecute",
    ])
    error_message = "The coredns toleration should match the DMZ node group taint"
  }

  assert {
    condition     = jsondecode(module.eks.cluster_addons["coredns"].configuration_values).nodeSelector.role == "dmz-1"
    error_message = "The coredns should be pinned to the dmz-1 label"
  }

  assert {
    condition     = length(jsondecode(module.eks.cluster_addons["coredns"].configuration_values).affinity) == 0
    error_message = "The pod anti-affinity should be dropped once coredns targets the DMZ nodes"
  }
}

run "node_groups_carry_the_expected_labels_and_platform" {
  command = plan

  variables {
    create_dmz_node_group = true
  }

  assert {
    condition = alltrue([
      module.eks.eks_managed_node_groups["worker-radar-base-test"].platform == "linux",
      module.eks.eks_managed_node_groups["dmz-radar-base-test"].platform == "linux",
    ])
    error_message = "Both node groups should run on the Linux platform"
  }

  assert {
    condition     = module.eks.eks_managed_node_groups["worker-radar-base-test"].node_group_labels.role == "worker"
    error_message = "The worker node group should carry the 'worker' label"
  }

  assert {
    condition     = module.eks.eks_managed_node_groups["dmz-radar-base-test"].node_group_labels.role == "dmz-1"
    error_message = "The DMZ node group should carry the 'dmz-1' label"
  }

  assert {
    condition     = one(module.eks.eks_managed_node_groups["dmz-radar-base-test"].node_group_taints).key == "dmz-pod"
    error_message = "The DMZ node group should be tainted with 'dmz-pod'"
  }

  assert {
    condition     = length(module.eks.eks_managed_node_groups["worker-radar-base-test"].node_group_taints) == 0
    error_message = "The worker node group should not declare any taints"
  }
}

run "cluster_name_and_gated_outputs_are_planned" {
  command = plan

  assert {
    condition     = output.radar_base_eks_cluster_name == "radar-base-test"
    error_message = "The cluster name output should forward module.eks.cluster_name"
  }

  assert {
    condition     = output.radar_base_eks_dmz_node_group_name == null
    error_message = "The DMZ node group output should be null while 'create_dmz_node_group' is false"
  }

  assert {
    condition     = output.radar_base_default_storage_class == "radar-base-ebs-sc-gp3"
    error_message = "The default storage class output should forward var.default_storage_class"
  }
}

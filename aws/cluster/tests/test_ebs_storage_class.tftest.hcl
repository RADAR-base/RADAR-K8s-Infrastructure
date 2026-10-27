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

run "all_storage_classes_are_rendered" {
  command = plan

  assert {
    condition = alltrue([
      length(kubectl_manifest.ebs_storage_classes) == 4,
      length(local.storage_classes) == 4,
    ])
    error_message = "One StorageClass manifest should be rendered per entry in local.storage_classes"
  }

  assert {
    condition     = toset(keys(kubectl_manifest.ebs_storage_classes)) == toset(["gp2", "gp3", "io1", "io2"])
    error_message = "The manifest keys should be the pre-defined volume types"
  }

  assert {
    condition = alltrue([
      for key, name in local.storage_classes :
      strcontains(kubectl_manifest.ebs_storage_classes[key].yaml_body, "name: ${name}\n")
    ])
    error_message = "Each manifest should be named after its entry in local.storage_classes"
  }

  assert {
    condition = alltrue([
      for key, manifest in kubectl_manifest.ebs_storage_classes :
      strcontains(manifest.yaml_body, "type: ${key}\n")
    ])
    error_message = "Each manifest should pass its own map key through as the EBS volume type"
  }
}

run "storage_classes_use_wait_for_first_consumer_and_retain" {
  command = plan

  assert {
    condition = alltrue([
      for _, manifest in kubectl_manifest.ebs_storage_classes :
      strcontains(manifest.yaml_body, "volumeBindingMode: WaitForFirstConsumer")
      && strcontains(manifest.yaml_body, "allowVolumeExpansion: true")
      && strcontains(manifest.yaml_body, "reclaimPolicy: Retain")
      && strcontains(manifest.yaml_body, "provisioner: ebs.csi.aws.com")
      && strcontains(manifest.yaml_body, "fstype: ext4")
      && strcontains(manifest.yaml_body, "apiVersion: storage.k8s.io/v1")
      && strcontains(manifest.yaml_body, "kind: StorageClass")
    ])
    error_message = "Every StorageClass should have the default values set for EBS CSI parameters"
  }
}

run "selected_class_becomes_the_default" {
  command = plan

  variables {
    default_storage_class = "radar-base-ebs-sc-io1"
  }

  assert {
    condition = alltrue([
      kubernetes_annotations.set_default_storage_class.metadata[0].name == "radar-base-ebs-sc-io1",
      kubernetes_annotations.set_default_storage_class.annotations["storageclass.kubernetes.io/is-default-class"] == "true",
      kubernetes_annotations.set_default_storage_class.force == true,
    ])
    error_message = "The chosen storage class should be annotated as the default"
  }

  assert {
    condition     = output.radar_base_default_storage_class == "radar-base-ebs-sc-io1"
    error_message = "The default storage class output should follow the setting"
  }
}

run "gp3_is_the_default_by_default" {
  command = plan

  assert {
    condition = alltrue([
      kubernetes_annotations.set_default_storage_class.metadata[0].name == "radar-base-ebs-sc-gp3",
      kubernetes_annotations.set_default_storage_class.annotations["storageclass.kubernetes.io/is-default-class"] == "true",
    ])
    error_message = "The 'radar-base-ebs-sc-gp3' should be the default unless overridden"
  }

  assert {
    condition = length([
      for _, manifest in kubectl_manifest.ebs_storage_classes : manifest.yaml_body
      if strcontains(manifest.yaml_body, "is-default-class")
    ]) == 0
    error_message = "The generated manifests themselves should not carry a default-class annotation which will be applied by kubernetes_annotations"
  }
}

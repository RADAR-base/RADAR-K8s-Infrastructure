resource "kubectl_manifest" "ebs_storage_classes" {
  for_each = local.storage_classes

  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1 
    kind: StorageClass
    metadata:
      name: ${each.value}
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
    allowVolumeExpansion: true
    reclaimPolicy: Retain
    parameters:
      type: ${each.key}
      fstype: ext4
  YAML
}

resource "kubernetes_annotations" "unset_eks_default_gp2" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
}

resource "kubernetes_annotations" "set_defaut_storage_class" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = var.defaut_storage_class
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "true"
  }

  depends_on = [
    kubectl_manifest.ebs_storage_classes,
    kubernetes_annotations.unset_eks_default_gp2,
  ]
}

output "radar_base_ebs_storage_class_gp2" {
  value = local.storage_classes.gp2
}

output "radar_base_ebs_storage_class_gp3" {
  value = local.storage_classes.gp3
}

output "radar_base_ebs_storage_class_io1" {
  value = local.storage_classes.io1
}

output "radar_base_ebs_storage_class_io2" {
  value = local.storage_classes.io2
}
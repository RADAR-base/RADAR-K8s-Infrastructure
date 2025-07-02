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

  depends_on = [
    module.eks
  ]
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

  depends_on = [
    module.eks
  ]
}

resource "kubernetes_annotations" "set_default_storage_class" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = var.default_storage_class
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "true"
  }

  depends_on = [
    kubectl_manifest.ebs_storage_classes,
    kubernetes_annotations.unset_eks_default_gp2,
  ]
}

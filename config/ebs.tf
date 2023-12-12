resource "kubectl_manifest" "ebs_sc_gp2" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1 
    kind: StorageClass
    metadata:
      name: ${local.storage_classes.gp2}
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
    allowVolumeExpansion: true
    reclaimPolicy: Retain
    parameters:
      type: gp3
      fstype: ext4
  YAML
}

resource "kubectl_manifest" "ebs_sc_gp3" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1 
    kind: StorageClass
    metadata:
      name: ${local.storage_classes.gp3}
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
    allowVolumeExpansion: true
    reclaimPolicy: Retain
    parameters:
      type: gp3
      fstype: ext4
  YAML
}

resource "kubectl_manifest" "ebs_sc_io1" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: ${local.storage_classes.io1}
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
    allowVolumeExpansion: true
    reclaimPolicy: Retain
    parameters:
      type: io1
      iopsPerGB: "100"
      fsType: ext4
  YAML
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

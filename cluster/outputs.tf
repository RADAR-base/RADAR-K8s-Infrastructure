output "radar_base_eks_cluster_name" {
  value = module.eks.cluster_name
}

output "radar_base_eks_cluser_endpoint" {
  value = module.eks.cluster_endpoint
}

output "radar_base_eks_dmz_node_group_name" {
  value = var.create_dmz_node_group ? element(split(":", module.eks.eks_managed_node_groups.dmz.node_group_id), 1) : null
}

output "radar_base_eks_worker_node_group_name" {
  value = element(split(":", module.eks.eks_managed_node_groups.worker.node_group_id), 1)
}

output "radar_base_vpc_public_subnets" {
  value = module.vpc.public_subnets
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

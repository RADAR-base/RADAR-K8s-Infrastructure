resource "aws_eip" "cluster_loadbalancer_eip" {
  count = var.enable_eip ? 1 : 0

  vpc              = true
  public_ipv4_pool = "amazon"
  tags             = merge(tomap({ "Name" : "${var.eks_cluster_name}-loadbalancer-eip" }), var.common_tags)

  #checkov:skip=CKV2_AWS_19:This EIP will be attached to the NLB when nginx-ingress is deployed
}

output "radar_base_eip_allocation_id" {
  value = var.enable_eip ? aws_eip.cluster_loadbalancer_eip[0].allocation_id : null
}

output "radar_base_eip_public_dns" {
  value = var.enable_eip ? aws_eip.cluster_loadbalancer_eip[0].public_dns : null
}

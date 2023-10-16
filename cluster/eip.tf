resource "aws_eip" "cluster_loadbalancer_eip" {
  vpc              = true
  public_ipv4_pool = "amazon"
  tags             = merge(tomap({ "Name" : "${var.environment}-${var.eks_cluster_base_name}-loadbalancer-eip" }), var.common_tags)
}

output "radar_base_eip_allocation_id" {
  value = aws_eip.cluster_loadbalancer_eip.allocation_id
}

output "radar_base_eip_public_dns" {
  value = aws_eip.cluster_loadbalancer_eip.public_dns
}
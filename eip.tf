resource "aws_eip" "cluster_loadbalancer_eip" {
  vpc              = true
  public_ipv4_pool = "amazon"
  tags             = merge(tomap({ "Name" : "${var.environment}-radar-base-cluster-loadbalancer-eip" }), var.common_tags)
}

output "radar_base_eip_allocation_id" {
  value = aws_eip.cluster_loadbalancer_eip.allocation_id
}
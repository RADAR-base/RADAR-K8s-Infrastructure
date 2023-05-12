resource "aws_eip" "cluster_loadbalancer_eip" {
  vpc              = true
  public_ipv4_pool = "amazon"
  tags             = merge(tomap({ "Name" : "${var.environment}-radar-base-cluster-loadbalancer-eip" }), var.common_tags)
}

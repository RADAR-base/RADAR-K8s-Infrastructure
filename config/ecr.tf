resource "aws_secretsmanager_secret" "dockerhub_credentials" {
  count       = var.enable_ecr_ptc ? 1 : 0
  name        = "ecr-pullthroughcache/radar-base-docker-hub"
  description = "Docker Hub credentials used by ECR pull-through cache"
  tags        = merge(tomap({ "Name" : "${var.eks_cluster_name}-sm-secret-docker-hub" }), var.common_tags)
}

resource "aws_secretsmanager_secret_version" "dockerhub_credentials_version" {
  count     = var.enable_ecr_ptc ? 1 : 0
  secret_id = aws_secretsmanager_secret.dockerhub_credentials[0].id

  secret_string = jsonencode({
    username    = var.docker_hub_username,
    accessToken = var.docker_hub_access_token,
  })
}

resource "aws_secretsmanager_secret_rotation" "dockerhub" {
  count     = var.enable_ecr_ptc ? 1 : 0
  secret_id = aws_secretsmanager_secret.dockerhub_credentials[0].id

  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_ecr_pull_through_cache_rule" "dockerhub" {
  count                 = var.enable_ecr_ptc ? 1 : 0
  ecr_repository_prefix = "docker-hub"
  upstream_registry_url = "registry-1.docker.io"
  credential_arn        = aws_secretsmanager_secret.dockerhub_credentials[0].arn
}

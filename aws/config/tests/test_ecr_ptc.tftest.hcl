mock_provider "aws" {
  source = "./tests/mocks"
}

mock_provider "archive" {}
mock_provider "helm" {}
mock_provider "kubectl" {}
mock_provider "kubernetes" {}
mock_provider "random" {}

variables {
  eks_cluster_name = "radar-base-test"
  radar_postgres_password = "test"
  docker_hub_username     = "test"
  docker_hub_access_token = "test"
  ghcr_username           = "test"
  ghcr_access_token       = "test"
  domain_name = { "radar-base.test" = "Z0123456789ABCDEFGHIJ" }
  enable_metrics          = false
  enable_karpenter        = false
  enable_msk              = false
  enable_rds              = false
  enable_route53          = false
  enable_ses              = false
  enable_s3               = false
  enable_eip              = false
  enable_ecr_ptc          = true
  with_dmz_pods           = false
  ses_bounce_destinations = []


  AWS_ACCESS_KEY_ID       = "test"
  AWS_SECRET_ACCESS_KEY   = "test"
}

run "pull_through_cache_plans_the_full_graph" {
  command = plan

  assert {
    condition = alltrue([
      length(aws_iam_role.ecr_repository_creator) == 1,
      length(aws_iam_policy.ecr_repository_permissions) == 1,
      length(aws_iam_role_policy_attachment.ecr_attach) == 1,
      length(aws_iam_role.secret_rotation_role) == 1,
      length(aws_iam_role_policy.secret_rotation_policy) == 1,
      length(aws_lambda_function.secret_rotation_function) == 1,
      length(aws_lambda_permission.secrets_manager_invoke) == 1,
      length(data.archive_file.secret_rotation_lambda_artifact) == 1,
      length(aws_secretsmanager_secret.dockerhub_credentials) == 1,
      length(aws_secretsmanager_secret_version.dockerhub_credentials_version) == 1,
      length(aws_secretsmanager_secret.ghcr_credentials) == 1,
      length(aws_secretsmanager_secret_version.ghcr_credentials_version) == 1,
      length(aws_ecr_pull_through_cache_rule.dockerhub) == 1,
      length(aws_ecr_pull_through_cache_rule.ghcr) == 1,
      length(aws_ecr_repository_creation_template.dockerhub) == 1,
      length(aws_ecr_repository_creation_template.ghcr) == 1,
      length(aws_secretsmanager_secret_rotation.dockerhub) == 1,
    ])
    error_message = "The enable_ecr_ptc should plan the complete pull-through cache graph for both upstreams"
  }
}

run "pull_through_cache_rules_point_at_the_expected_upstreams" {
  command = plan

  assert {
    condition     = aws_ecr_pull_through_cache_rule.dockerhub[0].upstream_registry_url == "registry-1.docker.io"
    error_message = "The Docker Hub rule should target registry-1.docker.io"
  }

  assert {
    condition     = aws_ecr_pull_through_cache_rule.ghcr[0].upstream_registry_url == "ghcr.io"
    error_message = "The GHCR rule should target ghcr.io"
  }

  assert {
    condition = alltrue([
      aws_ecr_pull_through_cache_rule.dockerhub[0].ecr_repository_prefix == "radar-base-docker-hub",
      aws_ecr_pull_through_cache_rule.ghcr[0].ecr_repository_prefix == "radar-base-ghcr",
    ])
    error_message = "Each pull-through cache rule should use its registry prefix"
  }
}

run "repository_creation_templates_apply_only_to_pull_through_cache" {
  command = plan

  assert {
    condition = alltrue([
      toset(aws_ecr_repository_creation_template.dockerhub[0].applied_for) == toset(["PULL_THROUGH_CACHE"]),
      toset(aws_ecr_repository_creation_template.ghcr[0].applied_for) == toset(["PULL_THROUGH_CACHE"]),
    ])
    error_message = "Creation templates should only be applied for PULL_THROUGH_CACHE repositories"
  }

  assert {
    condition = alltrue([
      aws_ecr_repository_creation_template.dockerhub[0].image_tag_mutability == "MUTABLE",
      aws_ecr_repository_creation_template.ghcr[0].image_tag_mutability == "MUTABLE",
    ])
    error_message = "Creation templates should allow mutable image tags"
  }

  assert {
    condition     = aws_ecr_repository_creation_template.dockerhub[0].prefix == "radar-base-docker-hub"
    error_message = "The Docker Hub template prefix should match the cache rule prefix"
  }
}

run "repository_creation_templates_carry_the_lifecycle_policy" {
  command = plan

  assert {
    condition = alltrue([
      length(jsondecode(aws_ecr_repository_creation_template.dockerhub[0].lifecycle_policy).rules) == 3,
      length(jsondecode(aws_ecr_repository_creation_template.ghcr[0].lifecycle_policy).rules) == 3,
    ])
    error_message = "Each creation template should embed a three-rule lifecycle policy"
  }

  assert {
    condition = alltrue([
      for rule in jsondecode(aws_ecr_repository_creation_template.dockerhub[0].lifecycle_policy).rules :
      rule.action.type == "expire"
    ])
    error_message = "Every lifecycle rule should be an expire action"
  }

  assert {
    condition = alltrue([
      for rule in jsondecode(aws_ecr_repository_creation_template.dockerhub[0].lifecycle_policy).rules :
      rule.rulePriority >= 1 && rule.rulePriority <= 3
    ])
    error_message = "Lifecycle rule priorities should be 1 through 3"
  }
}

run "environment_tag_is_stripped_from_ecr_resource_tags" {
  command = plan

  assert {
    condition     = !contains(keys(aws_ecr_repository_creation_template.dockerhub[0].resource_tags), "Environment")
    error_message = "The Environment tag must not be applied to ECR creation template resource tags"
  }

  assert {
    condition     = !contains(keys(aws_iam_role.ecr_repository_creator[0].tags), "Environment")
    error_message = "The Environment tag must not be applied to the ECR repository creator role"
  }

  assert {
    condition     = aws_iam_role.ecr_repository_creator[0].tags["Project"] == "radar-base"
    error_message = "Non-Environment common tags should still be applied"
  }

  assert {
    condition     = aws_secretsmanager_secret.dockerhub_credentials[0].tags["Environment"] == "dev"
    error_message = "Secrets Manager secrets should retain the Environment tag"
  }
}

# ecr.tf:139-148.
run "secret_rotation_lambda_is_configured" {
  command = plan

  assert {
    condition = alltrue([
      aws_lambda_function.secret_rotation_function[0].function_name == "radar-base-test-secret-rotation",
      aws_lambda_function.secret_rotation_function[0].runtime == "python3.11",
      aws_lambda_function.secret_rotation_function[0].handler == "index.lambda_handler",
    ])
    error_message = "The secret rotation lambda name, runtime and handler should match"
  }

  assert {
    condition     = one(aws_secretsmanager_secret_rotation.dockerhub[0].rotation_rules).automatically_after_days == 30
    error_message = "Docker Hub credentials should rotate every 30 days"
  }

  assert {
    condition     = aws_secretsmanager_secret.dockerhub_credentials[0].name == "ecr-pullthroughcache/radar-base-docker-hub"
    error_message = "The Docker Hub secret name should match the path"
  }

  assert {
    condition     = aws_secretsmanager_secret.ghcr_credentials[0].name == "ecr-pullthroughcache/radar-base-ghcr"
    error_message = "The GHCR secret name should match the path"
  }
}

run "secret_rotation_role_trusts_lambda" {
  command = plan

  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_role.secret_rotation_role[0].assume_role_policy).Statement :
      statement.Principal.Service == "lambda.amazonaws.com"
    ])
    error_message = "The secret rotation role should trust lambda.amazonaws.com"
  }
}

run "repository_creator_role_trusts_ecr" {
  command = plan

  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_role.ecr_repository_creator[0].assume_role_policy).Statement :
      statement.Principal.Service == "ecr.amazonaws.com"
    ])
    error_message = "The ECR repository creator role should trust ecr.amazonaws.com"
  }
}

run "disabling_pull_through_cache_removes_every_resource" {
  command = plan

  variables {
    enable_ecr_ptc = false
  }

  assert {
    condition = alltrue([
      length(aws_iam_role.ecr_repository_creator) == 0,
      length(aws_secretsmanager_secret.dockerhub_credentials) == 0,
      length(aws_secretsmanager_secret.ghcr_credentials) == 0,
      length(aws_ecr_pull_through_cache_rule.dockerhub) == 0,
      length(aws_ecr_pull_through_cache_rule.ghcr) == 0,
      length(aws_ecr_repository_creation_template.dockerhub) == 0,
      length(aws_lambda_function.secret_rotation_function) == 0,
      length(data.archive_file.secret_rotation_lambda_artifact) == 0,
    ])
    error_message = "Turning enable_ecr_ptc off should remove every pull-through cache resource"
  }
}

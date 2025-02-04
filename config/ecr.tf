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

resource "aws_ecr_pull_through_cache_rule" "dockerhub" {
  count                 = var.enable_ecr_ptc ? 1 : 0
  ecr_repository_prefix = "radar-base-docker-hub"
  upstream_registry_url = "registry-1.docker.io"
  credential_arn        = aws_secretsmanager_secret.dockerhub_credentials[0].arn
}

resource "aws_iam_role" "secret_rotation_role" {
  count = var.enable_ecr_ptc ? 1 : 0
  name  = "${var.eks_cluster_name}-sm-secret-rotation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole",
        Effect = "Allow",
      }
    ]
  })

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-sm-secret-rotation-lambda-role" }), var.common_tags)
}

resource "aws_iam_role_policy" "secret_rotation_policy" {
  count = var.enable_ecr_ptc ? 1 : 0
  name  = "${var.eks_cluster_name}-sm-secret-rotation-lambda-policy"
  role  = aws_iam_role.secret_rotation_role[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.dockerhub_credentials[0].arn
      },
      {
        Action   = "logs:*",
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

data "archive_file" "secret_rotation_lambda_artifact" {
  count            = var.enable_ecr_ptc ? 1 : 0
  type             = "zip"
  output_file_mode = "0666"
  output_path      = "${path.root}/.archive_files/dockerhub_secret_rotation.zip"

  source {
    filename = "index.py"
    content  = <<EOF
import boto3
import json

# The default function does not change secret values during rotation.
def lambda_handler(event, context):
    secret_id = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    client = boto3.client('secretsmanager')

    if step =='createSecret':
        response = client.get_secret_value(SecretId=secret_id)
        secret_string = response.get('SecretString')

        if not secret_string:
            raise ValueError("SecretString is empty or missing in the secret.")

        secret = json.loads(secret_string)

        if 'username' not in secret or 'accessToken' not in secret:
            raise ValueError("Required keys 'username' and 'accessToken' are missing in the secret.")

        client.put_secret_value(SecretId=secret_id, SecretString=secret_string, VersionStages=['AWSCURRENT'])
    elif step in ['setSecret', 'testSecret']:
        pass
    elif step == 'finishSecret':
        client.update_secret_version_stage(SecretId=secret_id, VersionStage='AWSCURRENT', MoveToVersionId=token)
    else:
        raise ValueError(f"Unsupported rotation step: {step}")
    print(f"Successfully completed the rotation on step: {step}")
EOF
  }
}

resource "aws_lambda_function" "secret_rotation_function" {
  count         = var.enable_ecr_ptc ? 1 : 0
  function_name = "${var.eks_cluster_name}-secret-rotation"
  role          = aws_iam_role.secret_rotation_role[0].arn
  runtime       = "python3.11"
  handler       = "index.lambda_handler"
  filename      = data.archive_file.secret_rotation_lambda_artifact[0].output_path

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-sm-secret-rotation" }), var.common_tags)
}

resource "aws_lambda_permission" "secrets_manager_invoke" {
  count         = var.enable_ecr_ptc ? 1 : 0
  statement_id  = "SecretsManagerInvokePermission"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation_function[0].function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = "${aws_secretsmanager_secret.dockerhub_credentials[0].arn}*"
}

resource "aws_secretsmanager_secret_rotation" "dockerhub" {
  count               = var.enable_ecr_ptc ? 1 : 0
  secret_id           = aws_secretsmanager_secret.dockerhub_credentials[0].id
  rotation_lambda_arn = aws_lambda_function.secret_rotation_function[0].arn

  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_ecr_repository_creation_template" "dockerhub" {
  count                = var.enable_ecr_ptc ? 1 : 0
  prefix               = "radar-base-docker-hub"
  description          = "A template for creating PTC repositories for images from Docker Hub"
  image_tag_mutability = "MUTABLE"
  custom_role_arn      = local.worker_node_group.node_role_arn

  applied_for = [
    "PULL_THROUGH_CACHE",
  ]

  lifecycle_policy = <<EOT
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire all untagged images but 1",
      "selection": {
        "tagStatus": "untagged",
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
          "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Only keep most recent 5 tagged images",
      "selection": {
        "tagStatus": "tagged",
        "tagPatternList": ["*"],
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
          "type": "expire"
      }
    },
    {
      "rulePriority": 3,
      "description": "Expire images older than 7 days",
      "selection": {
        "tagStatus": "any",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOT

  resource_tags = { for k, v in var.common_tags : k => v if k != "Environment" }
}

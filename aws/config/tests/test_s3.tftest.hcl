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
  enable_s3               = true
  enable_eip              = false
  enable_ecr_ptc          = false
  with_dmz_pods           = false
  ses_bounce_destinations = []

  AWS_ACCESS_KEY_ID       = "test"
  AWS_SECRET_ACCESS_KEY   = "test"
}

run "s3_plans_the_three_named_buckets" {
  command = plan

  assert {
    condition = alltrue([
      length(aws_s3_bucket.this) == 3,
      length(aws_s3_bucket_ownership_controls.this) == 3,
      length(aws_s3_bucket_server_side_encryption_configuration.this) == 3,
    ])
    error_message = "The enable_s3 should plan the buckets defined in local.s3_bucket_names"
  }

  assert {
    condition = alltrue([
      aws_s3_bucket.this["intermediate_output_storage"].bucket == "${var.eks_cluster_name}-intermediate-output-storage",
      aws_s3_bucket.this["output_storage"].bucket == "${var.eks_cluster_name}-output-storage",
      aws_s3_bucket.this["velero_backups"].bucket == "${var.eks_cluster_name}-velero-backups",
    ])
    error_message = "Bucket names should be prefixed with the cluster name"
  }
}

run "s3_buckets_enforce_bucket_owner_ownership" {
  command = plan

  assert {
    condition = alltrue([
      for key, bucket in aws_s3_bucket.this :
      one(aws_s3_bucket_ownership_controls.this[key].rule).object_ownership == "BucketOwnerEnforced"
    ])
    error_message = "Every bucket should set object_ownership to BucketOwnerEnforced"
  }
}

run "s3_buckets_encrypt_with_aes256" {
  command = plan

  assert {
    condition = alltrue([
      for key, bucket in aws_s3_bucket.this :
      one(aws_s3_bucket_server_side_encryption_configuration.this[key].rule)
      .apply_server_side_encryption_by_default[0]
      .sse_algorithm == "AES256"
    ])
    error_message = "Every bucket should apply server-side encryption with SSE algorithm AES256"
  }
}

run "s3_access_policy_covers_every_bucket" {
  command = plan

  assert {
    condition     = length(aws_iam_policy.s3_access) == 1
    error_message = "Exactly one S3 access policy should be created"
  }

  assert {
    condition = length([
      for statement in jsondecode(aws_iam_policy.s3_access[0].policy).Statement :
      statement if statement.Action == ["s3:ListBucket"]
    ]) == 1
    error_message = "The policy should contain exactly one ListBucket statement"
  }

  assert {
    condition = length([
      for statement in jsondecode(aws_iam_policy.s3_access[0].policy).Statement :
      statement if statement.Action == "s3:*Object"
    ]) == 1
    error_message = "The policy should contain exactly one s3:*Object statement"
  }

  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_policy.s3_access[0].policy).Statement :
      statement.Effect == "Allow"
    ])
    error_message = "Every statement in the S3 access policy should be an Allow"
  }

  assert {
    condition = alltrue([
      for bucket_name in local.s3_bucket_names :
      contains(
        flatten([
          for statement in jsondecode(aws_iam_policy.s3_access[0].policy).Statement : statement.Resource
        ]),
        "arn:aws:s3:::${bucket_name}",
      )
    ])
    error_message = "Every bucket ARN from local.s3_bucket_names should appear in the access policy"
  }

  assert {
    condition     = aws_iam_policy.s3_access[0].path == "/${var.eks_cluster_name}/"
    error_message = "The S3 access policy should be scoped to the cluster path"
  }
}

run "s3_creates_a_scoped_iam_user_and_key" {
  command = plan

  assert {
    condition = alltrue([
      length(aws_iam_user.s3_access) == 1,
      length(aws_iam_access_key.s3_access) == 1,
      length(aws_iam_user_policy_attachment.s3_access) == 1,
    ])
    error_message = "The enable_s3 should plan one IAM user, one access key and one policy attachment"
  }

  assert {
    condition     = aws_iam_user.s3_access[0].name == "${var.eks_cluster_name}-s3-access"
    error_message = "The S3 access user should be named after the cluster"
  }

  assert {
    condition     = aws_iam_user.s3_access[0].path == "/${var.eks_cluster_name}/"
    error_message = "The S3 access user should be scoped to the cluster path"
  }
}

run "s3_bucket_name_outputs_are_populated" {
  command = plan

  assert {
    condition = alltrue([
      output.radar_base_s3_intermediate_output_bucket_name == "${var.eks_cluster_name}-intermediate-output-storage",
      output.radar_base_s3_output_bucket_name == "${var.eks_cluster_name}-output-storage",
      output.radar_base_s3_velero_bucket_name == "${var.eks_cluster_name}-velero-backups",
    ])
    error_message = "Bucket name outputs should forward the values from local.s3_bucket_names"
  }
}

run "disabling_s3_removes_every_s3_resource" {
  command = plan

  variables {
    enable_s3 = false
  }

  assert {
    condition = alltrue([
      length(aws_s3_bucket.this) == 0,
      length(aws_s3_bucket_ownership_controls.this) == 0,
      length(aws_s3_bucket_server_side_encryption_configuration.this) == 0,
      length(aws_iam_user.s3_access) == 0,
      length(aws_iam_policy.s3_access) == 0,
      length(aws_iam_access_key.s3_access) == 0,
      length(aws_iam_user_policy_attachment.s3_access) == 0,
      output.radar_base_s3_output_bucket_name == null,
    ])
    error_message = "Turning enable_s3 off should remove every S3 resource and null its outputs"
  }
}

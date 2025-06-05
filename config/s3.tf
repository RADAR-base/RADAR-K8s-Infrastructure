resource "aws_s3_bucket" "this" {
  for_each = { for k, v in local.s3_bucket_names : k => v if var.enable_s3 }

  bucket = each.value
  tags   = merge(tomap({ "Name" : each.key }), var.common_tags)

  #checkov:skip=CKV2_AWS_6: This is implicitly guranateed and public access is blocked for S3 buckets
  #checkov:skip=CKV_AWS_18,CKV_AWS_144,CKV_AWS_21,CKV_AWS_145,CKV2_AWS_61,CKV2_AWS_62: These S3 rules should be applied case by case
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = { for k, v in local.s3_bucket_names : k => v if var.enable_s3 }

  bucket = aws_s3_bucket.this[each.key].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  depends_on = [aws_s3_bucket.this]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = { for k, v in local.s3_bucket_names : k => v if var.enable_s3 }

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_policy" "s3_access" {
  count = var.enable_s3 ? 1 : 0

  name        = "${var.eks_cluster_name}-s3-access"
  path        = "/${var.eks_cluster_name}/"
  description = "Allow S3 access for apps in ${var.eks_cluster_name} cluster"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : [for bucket_name in local.s3_bucket_names : "arn:aws:s3:::${bucket_name}"]
      },
      {
        "Effect" : "Allow",
        "Action" : "s3:*Object",
        "Resource" : [for bucket_name in local.s3_bucket_names : "arn:aws:s3:::${bucket_name}/*"]
      }
    ]
  })
  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-s3-access" }), var.common_tags)
}

resource "aws_iam_user" "s3_access" {
  count = var.enable_s3 ? 1 : 0

  name = "${var.eks_cluster_name}-s3-access"
  path = "/${var.eks_cluster_name}/"

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-s3-access" }), var.common_tags)
}

resource "aws_iam_access_key" "s3_access" {
  count = var.enable_s3 ? 1 : 0

  user = aws_iam_user.s3_access[0].name
}

resource "aws_iam_user_policy_attachment" "s3_access" {
  count = var.enable_s3 ? 1 : 0

  user       = aws_iam_user.s3_access[0].name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

output "radar_base_s3_intermediate_output_bucket_name" {
  value = var.enable_s3 ? local.s3_bucket_names["intermediate_output_storage"] : null
}

output "radar_base_s3_output_bucket_name" {
  value = var.enable_s3 ? local.s3_bucket_names["output_storage"] : null
}

output "radar_base_s3_velero_bucket_name" {
  value = var.enable_s3 ? local.s3_bucket_names["velero_backups"] : null
}

output "radar_base_s3_access_key" {
  value     = var.enable_s3 ? aws_iam_access_key.s3_access[0].id : null
  sensitive = true
}

output "radar_base_s3_secret_key" {
  value     = var.enable_s3 ? aws_iam_access_key.s3_access[0].secret : null
  sensitive = true
}

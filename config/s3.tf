resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3 ? 1 : 0

  vpc_id       = data.aws_vpc.main.id
  service_name = "com.amazonaws.${var.AWS_REGION}.s3"

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-s3-vpc-endpoint" }), var.common_tags)
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association" {
  count = var.enable_s3 ? 1 : 0

  route_table_id  = data.aws_vpc.main.main_route_table_id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

resource "aws_s3_bucket" "this" {
  for_each = { for k, v in local.s3_bucket_names : k => v if var.enable_s3 }

  bucket = each.value
  tags   = merge(tomap({ "Name" : each.key }), var.common_tags)
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = { for k, v in local.s3_bucket_names : k => v if var.enable_s3 }

  bucket = aws_s3_bucket.this[each.key].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [aws_s3_bucket.this]
}

resource "aws_s3_bucket_acl" "this" {
  for_each = { for k, v in local.s3_bucket_names : k => v if var.enable_s3 }

  bucket = aws_s3_bucket.this[each.key].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.this]
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
  value = var.enable_s3 ? aws_iam_access_key.s3_access[0].id : null
}

output "radar_base_s3_secret_key" {
  value     = var.enable_s3 ? aws_iam_access_key.s3_access[0].secret : null
  sensitive = true
}

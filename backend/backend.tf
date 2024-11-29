resource "aws_s3_bucket" "backend" {
  count = var.enable_backend ? 1 : 0

  bucket = var.backend_bucket_name
  tags   = merge(tomap({ "Name" : "${var.eks_cluster_name}-${var.backend_bucket_name}" }), var.common_tags)
}

resource "aws_s3_bucket_ownership_controls" "backend" {
  count = var.enable_backend ? 1 : 0

  bucket = aws_s3_bucket.backend[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [aws_s3_bucket.backend]
}

resource "aws_s3_bucket_acl" "backend" {
  count = var.enable_backend ? 1 : 0

  bucket = aws_s3_bucket.backend[0].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.backend]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend" {
  count = var.enable_backend ? 1 : 0

  bucket = aws_s3_bucket.backend[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "backend" {
  count = var.enable_backend ? 1 : 0

  name           = var.backend_state_locking
  hash_key       = "LockID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-backend-state-locking" }), var.common_tags)
}

resource "aws_iam_policy" "backend" {
  count = var.enable_backend ? 1 : 0

  name        = "${var.eks_cluster_name}-backend-access"
  path        = "/${var.eks_cluster_name}/"
  description = "Allow backend TF state access for admin users of ${var.eks_cluster_name} cluster"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:ListBucket",
        "Resource" : "arn:aws:s3:::${var.backend_bucket_name}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource" : "arn:aws:s3:::${var.backend_bucket_name}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ],
        "Resource" : "arn:aws:dynamodb:::table/${var.backend_state_locking}"
      }
    ]
  })
  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-backend-access" }), var.common_tags)
}

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

resource "aws_s3_bucket" "intermediate_output_storage" {
  count = var.enable_s3 ? 1 : 0

  bucket = "${var.eks_cluster_name}-intermediate-output-storage"

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-intermediate-output-storage" }), var.common_tags)
}

resource "aws_s3_bucket_ownership_controls" "intermediate_output" {
  count = var.enable_s3 ? 1 : 0

  bucket = aws_s3_bucket.intermediate_output_storage[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [aws_s3_bucket.intermediate_output_storage]
}

resource "aws_s3_bucket_acl" "intermediate_output" {
  count = var.enable_s3 ? 1 : 0

  bucket = aws_s3_bucket.intermediate_output_storage[0].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.intermediate_output]
}

resource "aws_s3_bucket" "output_storage" {
  count = var.enable_s3 ? 1 : 0

  bucket = "${var.eks_cluster_name}-output-storage"

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-output-storage" }), var.common_tags)
}

resource "aws_s3_bucket_ownership_controls" "output" {
  count = var.enable_s3 ? 1 : 0

  bucket = aws_s3_bucket.output_storage[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [aws_s3_bucket.output_storage]
}

resource "aws_s3_bucket_acl" "output" {
  count = var.enable_s3 ? 1 : 0

  bucket = aws_s3_bucket.output_storage[0].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.output]
}

resource "aws_s3_bucket" "velero_backups" {
  count = var.enable_s3 ? 1 : 0

  bucket = "${var.eks_cluster_name}-velero-backups"

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-velero-backups" }), var.common_tags)
}

resource "aws_s3_bucket_ownership_controls" "velero" {
  count = var.enable_s3 ? 1 : 0

  bucket = aws_s3_bucket.velero_backups[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [aws_s3_bucket.velero_backups]
}

resource "aws_s3_bucket_acl" "velero" {
  count = var.enable_s3 ? 1 : 0

  bucket = aws_s3_bucket.velero_backups[0].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.velero]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "intermediate_output_storage_encryption" {
  count = var.enable_s3 ? 1 : 0

  bucket = aws_s3_bucket.intermediate_output_storage[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "output_storage_encryption" {
  count = var.enable_s3 ? 1 : 0

  bucket = aws_s3_bucket.output_storage[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero_backups_encryption" {
  count = var.enable_s3 ? 1 : 0

  bucket = aws_s3_bucket.velero_backups[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "radar_base_s3_intermediate_output_bucket_name" {
  value = var.enable_s3 ? aws_s3_bucket.intermediate_output_storage[0].bucket : null
}

output "radar_base_s3_output_bucket_name" {
  value = var.enable_s3 ? aws_s3_bucket.intermediate_output_storage[0].bucket : null
}

output "radar_base_s3_velero_bucket_name" {
  value = var.enable_s3 ? aws_s3_bucket.intermediate_output_storage[0].bucket : null
}

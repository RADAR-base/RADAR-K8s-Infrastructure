resource "aws_vpc_endpoint" "s3" {
  vpc_id       = data.aws_vpc.main.id
  service_name = "com.amazonaws.${var.AWS_REGION}.s3"

  tags = merge(tomap({ "Name" : "s3-vpc-endpoint" }), var.common_tags)
}

resource "aws_vpc_endpoint_route_table_association" "route_table_association" {
  route_table_id  = data.aws_vpc.main.main_route_table_id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_s3_bucket" "intermediate_output_storage" {
  bucket = "radar-base-${var.environment}-intermediate-output-storage"
  acl    = "private"

  tags = merge(tomap({ "Name" : "radar-base-eks-intermediate-output-storage" }), var.common_tags)
}

resource "aws_s3_bucket" "output_storage" {
  bucket = "radar-base-${var.environment}-output-storage"
  acl    = "private"

  tags = merge(tomap({ "Name" : "radar-base-eks-output-storage" }), var.common_tags)
}

resource "aws_s3_bucket" "velero_backups" {
  bucket = "radar-base-${var.environment}-velero-backups"
  acl    = "private"

  tags = merge(tomap({ "Name" : "radar-base-eks-velero-backups" }), var.common_tags)
}

resource "aws_s3_bucket_server_side_encryption_configuration" "intermediate_output_storage_encryption" {
  bucket = aws_s3_bucket.intermediate_output_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "output_storage_encryption" {
  bucket = aws_s3_bucket.output_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero_backups_encryption" {
  bucket = aws_s3_bucket.velero_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "radar_base_s3_intermediate_output_bucket_name" {
  value = aws_s3_bucket.intermediate_output_storage.bucket
}

output "radar_base_s3_output_bucket_name" {
  value = aws_s3_bucket.output_storage.bucket
}

output "radar_base_s3_velero_bucket_name" {
  value = aws_s3_bucket.velero_backups.bucket
}

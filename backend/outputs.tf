output "backend_bucket_name" {
  value = var.enable_backend ? var.backend_bucket_name : null
}

output "backend_state_locking" {
  value = var.enable_backend ? var.backend_state_locking : null
}

output "backend_aws_region" {
  value = var.enable_backend ? var.AWS_REGION : null
}

output "backend_access_iam_policy" {
  value = var.enable_backend ? aws_iam_policy.backend[0].arn : null
}
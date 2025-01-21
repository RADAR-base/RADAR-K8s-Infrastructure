variable "AWS_REGION" {
  type        = string
  description = "Target AWS region"
  default     = "eu-west-2"
}

variable "AWS_ACCESS_KEY_ID" {
  type        = string
  description = "AWS access key associated with an IAM account"
  sensitive   = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  type        = string
  description = "AWS secret key associated with the access key"
  sensitive   = true
}

variable "AWS_SESSION_TOKEN" {
  type        = string
  description = "Session token for temporary security credentials from AWS STS"
  default     = ""
  sensitive   = true
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"

  validation {
    condition     = length(var.eks_cluster_name) > 0
    error_message = "The cluster name cannot be empty."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags associated to resources created"
  default = {
    Project     = "radar-base"
    Environment = "dev"
  }
}

variable "enable_backend" {
  type        = bool
  description = "Do you need a remote backend for storing TF state? [true, false]"
}

variable "backend_bucket_name" {
  type        = string
  description = "Default name of the S3 bucket for storing TF state"
  default     = "radar-base-infrastructure"
}

variable "backend_state_locking" {
  type        = string
  description = "Default name of the DynamoDB table for TF state locking"
  default     = "radar-base-infrastructure-state-locking"
}

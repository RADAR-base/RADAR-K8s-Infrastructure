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

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags associated to resources created"
  default = {
    Project     = "radar-base-development"
    Environment = "dev"
  }
}

variable "domain_name" {
  type        = string
  description = "Top level domain for deployed applications"
  default     = "change-me-radar-base-dummy-domain.net"
}

variable "instance_capacity_type" {
  type        = string
  description = "Capacity type used by EKS managed node groups"
  default     = "SPOT"

  validation {
    condition     = var.instance_capacity_type == "ON_DEMAND" || var.instance_capacity_type == "SPOT"
    error_message = "Invalid instance capacity type. Allowed values are 'ON_DEMAND' or 'SPOT'."
  }
}

variable "kafka_version" {
  type    = string
  default = "3.2.0"
}

variable "postgres_version" {
  type    = string
  default = "13.7"

}

variable "karpenter_version" {
  type    = string
  default = "v0.29.0"
}

variable "radar_postgres_password" {
  type        = string
  description = "Password for the PostgreSQL database used by Radar components"
  default     = "change_me"
  sensitive   = true
}

variable "enable_karpenter" {
  type        = bool
  description = "Do you need Karpenter? [true, false]"
}

variable "enable_msk" {
  type        = bool
  description = "Do you need MSK? [true, false]"
}

variable "enable_rds" {
  type        = bool
  description = "Do you need RDS? [true, false]"
}

variable "enable_route53" {
  type        = bool
  description = "Do you need Route53? [true, false]"
}

variable "enable_ses" {
  type        = bool
  description = "Do you need SES? [true, false]"
}

variable "enable_s3" {
  type        = bool
  description = "Do you need S3? [true, false]"
}

variable "enable_eip" {
  type        = bool
  description = "Do you need EIP? [true, false]"
}
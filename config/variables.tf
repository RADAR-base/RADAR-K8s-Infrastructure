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

variable "AWS_PROFILE" {
  type        = string
  description = "AWS Profile that resources are created in"
  default     = "default"
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
    Project     = "radar-base"
    Environment = "dev"
  }
}

variable "domain_name" {
  type        = map(string)
  description = "Pair of top level domain and hosted zone ID for deployed applications"
  default     = {}

  validation {
    condition     = length(var.domain_name) < 2
    error_message = "Multiple domain and hosted zone pairs are not supported."
  }
}

variable "ses_bounce_destinations" {
  type        = list(string)
  description = "List of email addresses for receiving bounced email notifications"
  default     = []
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

variable "metrics_server_version" {
  type    = string
  default = "3.12.1"
}

variable "kubernetes_dashboard_version" {
  type    = string
  default = "7.3.2"
}

variable "kafka_version" {
  type    = string
  default = "3.2.0"
}

variable "postgres_version" {
  type    = string
  default = "13.14"

}

variable "karpenter_version" {
  type    = string
  default = "v0.29.0"
}

variable "radar_postgres_password" {
  type        = string
  description = "Password for the PostgreSQL database used by Radar components"
  # Make sure to change the default value when var.enable_rds is set to "true"
  default   = "change_me"
  sensitive = true
}

variable "with_dmz_pods" {
  type        = bool
  description = "Whether or not to utilise the DMZ node group if it exists"
  default     = false
}

variable "enable_metrics" {
  type        = bool
  description = "Do you need Metrics Server? [true, false]"
}

variable "enable_karpenter" {
  type        = bool
  description = "Do you need Karpenter? [true, false]"
}

variable "enable_msk" {
  type        = bool
  description = "Do you need MSK? [true, false]"
}

variable "enable_msk_logging" {
  type        = bool
  description = "Do you need logging on MSK brokers? [true, false]"
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

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

variable "karpenter_version" {
  type    = string
  default = "1.3.3"
}

variable "karpenter_ami_version_alias" {
  type        = string
  description = "Selector alias for the AMI version used by Karpenter EC2 node class"
  default     = "al2023@v20250519"
}

variable "karpenter_node_pools" {
  type = map(object({
    architecture           = list(string)
    os                     = list(string)
    instance_capacity_type = list(string)
    instance_category      = list(string)
    instance_cpu           = list(string)
  }))
  description = "Configuration for the Karpenter node pool(s) with each key being the node pool name"
  default     = {}

  # Exemplary value for karpenter_node_pools:
  # {
  #   default = {
  #     architecture           = ["amd64"]
  #     instance_capacity_type = ["spot"]
  #     instance_category      = ["c", "m", "r"]
  #     instance_cpu           = ["2", "4", "8"]
  #     os                     = ["linux"]
  #   },
  #   on-demand = {
  #     architecture           = ["amd64"]
  #     instance_capacity_type = ["on-demand"]
  #     instance_category      = ["c", "m", "r"]
  #     instance_cpu           = ["2", "4", "8"]
  #     os                     = ["linux"]
  #   }
  # }

  validation {
    condition = alltrue([
      for np_name, np_config in var.karpenter_node_pools :
      alltrue([
        for capacity_type in np_config.instance_capacity_type :
        contains(["spot", "on-demand", "reserved"], capacity_type)
      ])
    ])

    error_message = "Invalid instance capacity type. Allowed values are 'on-demand', 'spot' or 'reserved'."
  }
}

variable "metrics_server_version" {
  type        = string
  description = "Version of the Metrics Server"
  default     = "3.12.1"
}

variable "kubernetes_dashboard_version" {
  type        = string
  description = "Version of the Kubernetes Dashboard"
  default     = "7.3.2"
}

variable "kafka_version" {
  type        = string
  description = "Version of the Kafka to be used for MSK"
  default     = "3.9.x"
}

variable "postgres_version" {
  type        = string
  description = "Version of the PostgreSQL to be used for RDS"
  default     = "13.20"
}

variable "postgres_read_replicas" {
  type        = number
  default     = 0
  description = "Number of PostgreSQL read replicas if needed"
}

variable "radar_postgres_password" {
  type        = string
  description = "Password for the PostgreSQL database used by Radar components"
  sensitive   = true
}

variable "docker_hub_username" {
  type        = string
  description = "Docker Hub username for ECR pull through cache"
  sensitive   = true
}

variable "docker_hub_access_token" {
  type        = string
  description = "Docker Hub access token for ECR pull through cache"
  sensitive   = true
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

  validation {
    condition     = (!var.enable_rds) || (var.enable_rds && length(var.radar_postgres_password) > 0)
    error_message = "Enabling RDS requires 'radar_postgres_password' to be set."
  }
}

variable "enable_rds_multi_az" {
  type        = bool
  description = "Do you need RDS Multi-AZ? [true, false]"
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

variable "enable_ecr_ptc" {
  type        = bool
  description = "Do you need ECR pull-through cache? [true, false]"

  validation {
    condition     = (!var.enable_ecr_ptc) || (var.enable_ecr_ptc && length(var.docker_hub_username) > 0 && length(var.docker_hub_access_token) > 0)
    error_message = "Enabling ECR pull-through cache requires 'docker_hub_username' and 'docker_hub_access_token' to be set."
  }
}

variable "AWS_REGION" {
  type        = string
  description = "Target AWS region"
  default     = "eu-west-2"
}

variable "AWS_ACCESS_KEY_ID" {
  type        = string
  description = "AWS access key associated with an IAM account"
  default     = ""
  sensitive   = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  type        = string
  description = "AWS secret key associated with the access key"
  default     = ""
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

variable "common_tags" {
  type        = map(string)
  description = "Common tags associated to resources created"
  default = {
    Project     = "radar-base"
    Environment = "dev"
  }
}

variable "eks_kubernetes_version" {
  type        = string
  description = "Amazon EKS Kubernetes version"
  default     = "1.31"

  validation {
    condition     = contains(["1.31", "1.30", "1.29", "1.28"], var.eks_kubernetes_version)
    error_message = "Invalid EKS Kubernetes version. Supported versions are '1.31', '1.30', '1.29', '1.28'."
  }
}

variable "instance_types" {
  type        = list(any)
  description = "List of instance types used by EKS managed node groups"
  default     = ["m5.large", "m5d.large", "m5a.large", "m5ad.large", "m4.large"]
}

variable "instance_capacity_type" {
  type        = string
  description = "Capacity type used by EKS managed node groups"
  default     = "SPOT"

  validation {
    condition     = var.instance_capacity_type == "ON_DEMAND" || var.instance_capacity_type == "SPOT"
    error_message = "Invalid instance capacity type. Allowed values are 'ON_DEMAND', 'SPOT'."
  }
}

variable "worker_node_size" {
  type        = map(number)
  description = "Node size of the worker node group"
  default = {
    "desired" = 2
    "min"     = 0
    "max"     = 10
  }
}

variable "eks_admins_group_users" {
  type        = list(string)
  description = "EKS admin IAM user group"
  default     = []
}

variable "create_dmz_node_group" {
  type        = bool
  description = "Whether or not to create a DMZ node group with taints"
  default     = false
}

variable "dmz_node_size" {
  type        = map(number)
  description = "Node size of the DMZ node group"
  default = {
    "desired" = 1
    "min"     = 0
    "max"     = 2
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "vpc_private_subnet_cidr" {
  description = "List of private subnet configurations"
  type        = list(any)
  default = [
    "10.0.0.0/19",
    "10.0.32.0/19",
    "10.0.64.0/19",
  ]
}

variable "vpc_public_subnet_cidr" {
  description = "List of public subnet configurations"
  type        = list(any)
  default = [
    "10.0.96.0/19",
    "10.0.128.0/19",
    "10.0.160.0/19",
  ]
}

variable "default_storage_class" {
  type        = string
  description = "Default storage class used for describing the EBS usage"
  default     = "radar-base-ebs-sc-gp2"

  validation {
    condition     = var.default_storage_class == "radar-base-ebs-sc-gp2" || var.default_storage_class == "radar-base-ebs-sc-gp3" || var.default_storage_class == "radar-base-ebs-sc-io1" || var.default_storage_class == "radar-base-ebs-sc-io2"
    error_message = "Invalid storage class. Allowed values are 'radar-base-ebs-sc-gp2', 'radar-base-ebs-sc-gp3', 'radar-base-ebs-sc-io1' or 'radar-base-ebs-sc-io2'."
  }
}

variable "ecr_repository_names" {
  type        = list(string)
  description = "Default prefixes for ECR repositories if used for hosting the images"
  default = [
    "ecr-public*",
    "k8s*",
    "quay*",
    "docker-hub*",
    "radarbase*",
  ]
}

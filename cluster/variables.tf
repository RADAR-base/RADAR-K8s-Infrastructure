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
    Project     = "radar-base"
    Environment = "dev"
  }
}

variable "eks_kubernetes_version" {
  type        = string
  description = "Amazon EKS Kubernetes version"
  default     = "1.27"

  validation {
    condition     = contains(["1.27", "1.26", "1.25"], var.eks_kubernetes_version)
    error_message = "Invalid EKS Kubernetes version. Supported versions are  '1.27', '1.26', '1.25'."
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

variable "defaut_storage_class" {
  type        = string
  description = "Default storage class used for describing the EBS usage"
  default     = "radar-base-ebs-sc-gp2"

  validation {
    condition     = var.defaut_storage_class == "radar-base-ebs-sc-gp2" || var.defaut_storage_class == "radar-base-ebs-sc-gp3" || var.defaut_storage_class == "radar-base-ebs-sc-io1" || var.defaut_storage_class == "radar-base-ebs-sc-io2"
    error_message = "Invalid storage class. Allowed values are 'radar-base-ebs-sc-gp2', 'radar-base-ebs-sc-gp3', 'radar-base-ebs-sc-io1' or 'radar-base-ebs-sc-io2'."
  }
}

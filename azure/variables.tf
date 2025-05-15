variable "subscription_id" {
  description = "The subscription ID where resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "testing"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "sander"
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "allowed_devops_ips" {
  description = "List of IP addresses allowed to access the database for DevOps purposes"
  type        = list(string)
  default     = []
}

variable "aks_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "Size of the VM for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
} 

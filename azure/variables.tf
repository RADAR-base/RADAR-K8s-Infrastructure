variable "subscription_id" {
  description = "The subscription ID where resources will be created"
  type        = string
  default     = "65c10e6e-5fcf-43f8-b928-9b2d4167bbd1"
  # default     = "f9a80383-5b9c-483a-8257-97bb0ac4a447"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "rg-radarbase"
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "psqladmin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
  default     = "aVe2irYv"
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

variable "terraform_principal_id" {
  description = "The Object ID of the principal that will be used to manage the Key Vault"
  type        = string
  default     = "65c10e6e-5fcf-43f8-b928-9b2d4167bbd1"
}

variable "administrator_password" {
  description = "The administrator password for the PostgreSQL Flexible Server"
  type        = string
  sensitive   = true
  default     = "aVe2irYv"
} 
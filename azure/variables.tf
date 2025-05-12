variable "subscription_id" {
  description = "The subscription ID where resources will be created"
  type        = string
  default     = "f9a80383-5b9c-483a-8257-97bb0ac4a447"
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
  default     = "radar-test"
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
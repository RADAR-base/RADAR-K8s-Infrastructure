variable "subscription_id" {
  description = "The subscription ID where resources will be created"
  type        = string
  default     = "" # set subscription ID
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
  default     = "radar-base"
}

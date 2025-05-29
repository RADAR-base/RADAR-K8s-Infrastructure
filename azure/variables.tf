variable "subscription_id" {
  description = "The subscription ID where resources will be created"
  type        = string
  default     = "65c10e6e-5fcf-43f8-b928-9b2d4167bbd1"
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

variable "common_tags" {
  type        = map(string)
  description = "Common tags associated to resources created"
  default = {
    Project     = "radar-base"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
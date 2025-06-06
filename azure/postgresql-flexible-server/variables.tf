variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "administrator_login" {
  description = "The administrator login name for the PostgreSQL server"
  type        = string
  default     = "psqladmin"
}

variable "environment" {
  description = "Environment value"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
}

variable "location" {
  description = "Target Azure location to deploy the resource"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "resource_group_name" {
  description = "Name of existing resource group to deploy resources into"
  type        = string
} 
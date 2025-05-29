variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, test, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the virtual network"
  type        = string
}

variable "location" {
  description = "The location/region where the virtual network will be created"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "The address prefixes for the main subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "subnet_address_prefixes_psql" {
  description = "The address prefixes for the PostgreSQL subnet"
  type        = list(string)
  default     = ["10.0.4.0/24"]
}

variable "use_existing_subnet" {
  description = "Whether to use existing subnets instead of creating new ones"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
} 
variable "AWS_REGION" {
  type    = string
  default = "eu-west-2"
}

variable "AWS_ACCESS_KEY_ID" {
  type      = string
  sensitive = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  type      = string
  sensitive = true
}

variable "AWS_SESSION_TOKEN" {
  type      = string
  default   = ""
  sensitive = true
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "common_tags" {
  type = map(string)
  default = {
    Project     = "radar-base-development"
    Environment = "dev"
  }
}

variable "cluster_name" {
  type = string
}

variable "instance_capacity_type" {
  type    = string
  default = "SPOT"

  validation {
    condition     = var.instance_capacity_type == "ON_DEMAND" || var.instance_capacity_type == "SPOT"
    error_message = "Invalid instance capacity type. Allowed values are 'ON_DEMAND' or 'SPOT'."
  }
}

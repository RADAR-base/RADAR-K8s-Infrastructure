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

variable "eks_cluster_version" {
  type    = string
  default = "1.26"
}

variable "eks_addon_version" {
  type = map(string)
  default = {
    "coredns"        = "v1.9.3-eksbuild.2"
    "kube_proxy"     = "v1.25.6-eksbuild.2"
    "vpc_cni"        = "v1.12.6-eksbuild.1"
    "ebs_csi_driver" = "v1.16.0-eksbuild.1"
  }
}

variable "instance_types" {
  type    = list(any)
  default = ["m5a.large", "m5a.xlarge"]
}

variable "instance_capacity_type" {
  type    = string
  default = "SPOT"

  validation {
    condition     = var.instance_capacity_type == "ON_DEMAND" || var.instance_capacity_type == "SPOT"
    error_message = "Invalid instance capacity type. Allowed values are 'ON_DEMAND' or 'SPOT'."
  }
}

variable "dmz_node_size" {
  type = map(number)
  default = {
    "desired" = 1
    "min"     = 1
    "max"     = 2
  }
}

variable "worker_node_size" {
  type = map(number)
  default = {
    "desired" = 6
    "min"     = 1
    "max"     = 10
  }
}

variable "eks_admins_group_users" {
  type    = list(string)
  default = []
}

variable "hosted_zone_name" {
  type    = string
  default = ""
}

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

variable "management_portal_postgres_password" {
  type      = string
  default   = "CHANGE_ME"
  sensitive = true
}

variable "radar_appserver_postgres_password" {
  type      = string
  default   = "CHANGE_ME"
  sensitive = true
}

variable "radar_rest_sources_backend_postgres_password" {
  type      = string
  default   = "CHANGE_ME"
  sensitive = true
}

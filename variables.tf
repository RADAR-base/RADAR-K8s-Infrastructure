variable "region" {
  type    = string
  default = "eu-west-2"
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

variable "eks_cluster_version" {
  type    = string
  default = "1.25"
}

variable "coredns_version" {
  type    = string
  default = "v1.9.3-eksbuild.2"
}

variable "kube_proxy_version" {
  type    = string
  default = "v1.25.6-eksbuild.2"
}

variable "vpc_cni_version" {
  type    = string
  default = "v1.12.6-eksbuild.1"
}

variable "ebs_csi_driver_version" {
  type    = string
  default = "v1.16.0-eksbuild.1"
}

variable "instance_types" {
  type    = list(any)
  default = ["m5a.large", "m5a.xlarge"]
}

variable "eks_admins_group_users" {
  type    = list(string)
  default = []
}

variable "hosted_zone_name" {
  type    = string
  default = ""
}

variable "AWS_ACCESS_KEY_ID" {
  type = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}

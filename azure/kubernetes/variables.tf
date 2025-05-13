variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31.7"
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "172.16.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "172.16.0.10"
}

variable "pod_cidr" {
  description = "Pod CIDR"
  type        = string
  default     = "10.244.0.0/16"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
} 
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = module.network.vnet_id
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = module.network.vnet_id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = module.network.subnet_id
}

output "kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.kubernetes.cluster_id
}

output "kubernetes_cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = module.kubernetes.cluster_id
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = module.kubernetes.kube_config
  sensitive   = true
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = module.registry.acr_id
}

output "container_registry_login_server" {
  description = "Login server of the container registry"
  value       = module.registry.login_server
}

output "container_registry_admin_username" {
  description = "Admin username of the container registry"
  value       = module.registry.admin_username
}

output "container_registry_admin_password" {
  description = "Admin password of the container registry"
  value       = module.registry.admin_password
  sensitive   = true
} 
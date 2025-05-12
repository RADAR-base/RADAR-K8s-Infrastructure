output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL Server"
  value       = azurerm_postgresql_server.main.fqdn
}

output "postgresql_database_name" {
  description = "Name of the PostgreSQL Database"
  value       = azurerm_postgresql_database.main.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.agw.ip_address
} 
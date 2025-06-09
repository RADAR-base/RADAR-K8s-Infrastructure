output "acr_id" {
  description = "Azure Container Registry ID"
  value       = azurerm_container_registry.main.id
}

output "login_server" {
  description = "ACR login server"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "ACR admin username"
  value       = azurerm_container_registry.main.admin_username
}

output "admin_password" {
  description = "ACR admin password"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

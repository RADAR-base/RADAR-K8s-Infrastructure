output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_id" {
  description = "The ID of the main subnet"
  value       = var.use_existing_subnet ? data.azurerm_subnet.existing_main[0].id : azurerm_subnet.main[0].id
}

output "psql_subnet_id" {
  description = "The ID of the PostgreSQL subnet"
  value       = var.use_existing_subnet ? data.azurerm_subnet.existing_psql[0].id : azurerm_subnet.psql[0].id
}

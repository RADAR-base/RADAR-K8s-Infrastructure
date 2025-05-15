# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project}-${var.environment}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.project}-${var.environment}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_address_prefixes
} 
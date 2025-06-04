terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project}-${var.environment}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

data "azurerm_subnet" "existing_main" {
  count                = var.use_existing_subnet ? 1 : 0
  name                 = "${var.project}-${var.environment}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
}

data "azurerm_subnet" "existing_psql" {
  count                = var.use_existing_subnet ? 1 : 0
  name                 = "${var.project}-${var.environment}-psql-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
}

# Subnet
resource "azurerm_subnet" "main" {
  count                = var.use_existing_subnet ? 0 : 1
  name                 = "${var.project}-${var.environment}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_address_prefixes
}

# Subnet psql
resource "azurerm_subnet" "psql" {
  count                = var.use_existing_subnet ? 0 : 1
  name                 = "${var.project}-${var.environment}-psql-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_address_prefixes_psql
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
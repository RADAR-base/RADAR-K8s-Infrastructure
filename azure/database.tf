# Azure PostgreSQL Server
resource "azurerm_postgresql_server" "main" {
  name                = "psql-${var.project}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  sku_name = "GP_Gen5_2"

  storage_mb                   = 51200
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled           = true

  administrator_login          = var.postgres_admin_username
  administrator_login_password = var.postgres_admin_password
  version                     = "11"
  ssl_enforcement_enabled     = true
}

# Azure PostgreSQL Database
resource "azurerm_postgresql_database" "main" {
  name                = "db-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.main.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# PostgreSQL Firewall Rule for AKS Subnet
resource "azurerm_postgresql_firewall_rule" "aks_subnet" {
  name                = "AllowAKSSubnet"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.main.name
  start_ip_address    = cidrhost(azurerm_subnet.aks.address_prefixes[0], 0)
  end_ip_address      = cidrhost(azurerm_subnet.aks.address_prefixes[0], -1)
}

# PostgreSQL Firewall Rule for Database Subnet
resource "azurerm_postgresql_firewall_rule" "database_subnet" {
  name                = "AllowDatabaseSubnet"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.main.name
  start_ip_address    = cidrhost(azurerm_subnet.database.address_prefixes[0], 0)
  end_ip_address      = cidrhost(azurerm_subnet.database.address_prefixes[0], -1)
}

# PostgreSQL Firewall Rule for DevOps IPs
resource "azurerm_postgresql_firewall_rule" "devops_ips" {
  for_each            = toset(var.allowed_devops_ips)
  name                = "AllowDevOpsIP-${replace(each.value, ".", "-")}"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.main.name
  start_ip_address    = each.value
  end_ip_address      = each.value
}

# PostgreSQL Virtual Network Rule
resource "azurerm_postgresql_virtual_network_rule" "main" {
  name                = "postgresql-vnet-rule"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.main.name
  subnet_id           = azurerm_subnet.database.id
} 
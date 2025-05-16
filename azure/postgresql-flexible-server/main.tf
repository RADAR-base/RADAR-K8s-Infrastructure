module "postgresql-flexible-server" {
  source  = "data-platform-hq/postgresql-flexible-server/azurerm"
  version = "1.3.0"
  env     = var.environment
  tags    = var.tags
  location = var.location
  suffix   = var.project
  project  = var.project
  resource_group = var.resource_group_name
  zone = null
  psql_version = 16
  # sku_name = "Standard_B1ms"
  ip_rules  = {}
  databases = []
} 
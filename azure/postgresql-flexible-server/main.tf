terraform {
  required_version = ">= 1.0.0"
}

module "postgresql-flexible-server" {
  source              = "data-platform-hq/postgresql-flexible-server/azurerm"
  version             = "1.3.0"
  env                 = var.environment
  tags                = var.tags
  location            = var.location
  suffix              = var.project
  project             = var.project
  resource_group      = var.resource_group_name
  zone                = null
  psql_version        = 16
  sku_name            = "B_Standard_B1ms"
  ip_rules            = {}
  databases           = []
  administrator_login = var.administrator_login

  #checkov:skip=CKV_TF_1: This is implicitly guranateed and public access is blocked for Azure's ASK

}

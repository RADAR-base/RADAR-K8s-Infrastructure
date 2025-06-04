locals {
  resource_group_name = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
  }
  location = "northeurope"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

# Use network module
module "network" {
  source = "./network"

  project             = var.project
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  use_existing_subnet = false # Manage subnet with Terraform
  tags                = local.tags

  depends_on = [azurerm_resource_group.main]
}

# Use container registry module
module "registry" {
  source = "./registry"

  project             = var.project
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags

  depends_on = [azurerm_resource_group.main]
}

# Use Kubernetes module
module "kubernetes" {
  source = "./kubernetes"

  project             = var.project
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.network.subnet_id
  tags                = local.tags

  # ACR related variables
  acr_id = module.registry.acr_id

  depends_on = [
    azurerm_resource_group.main,
    module.network,
    module.registry
  ]
}

module "postgresql-flexible-server" {
  source = "./postgresql-flexible-server"

  environment         = var.environment
  tags                = local.tags
  location            = local.location
  project             = var.project
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_resource_group.main]
}
# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project, "-", "")}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  tags = var.tags
} 
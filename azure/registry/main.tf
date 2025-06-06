terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project, "-", "")}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  tags = var.tags

  #checkov:skip=CKV_AZURE_237,CKV_AZURE_233,CKV_AZURE_167,CKV_AZURE_137,CKV_AZURE_164,CKV_AZURE_165,CKV_AZURE_166,CKV_AZURE_139: This is implicitly guranateed and public access is blocked for Azure's ACR
}

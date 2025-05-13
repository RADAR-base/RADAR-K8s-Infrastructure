locals {
  resource_group_name = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Validate subscription ID
data "azurerm_subscription" "current" {
  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

# 使用网络模块
module "network" {
  source = "./network"

  project            = var.project
  environment        = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location           = var.location
  tags               = local.tags
}

# 使用容器注册表模块
module "registry" {
  source = "./registry"

  project            = var.project
  environment        = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location           = var.location
  tags               = local.tags
}

# 使用 Kubernetes 模块
module "kubernetes" {
  source = "./kubernetes"

  project            = var.project
  environment        = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location           = var.location
  subnet_id          = module.network.subnet_id
  tags               = local.tags

  # ACR 相关变量
  acr_id             = module.registry.acr_id
  acr_login_server   = module.registry.login_server
  acr_admin_username = module.registry.admin_username
  acr_admin_password = module.registry.admin_password
}

# AKS 到 ACR 的角色分配
resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id                     = module.kubernetes.kubelet_identity[0].object_id
  role_definition_name            = "AcrPull"
  scope                           = module.registry.acr_id
  skip_service_principal_aad_check = true
} 
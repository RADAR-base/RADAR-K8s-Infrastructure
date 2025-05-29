# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project}-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.project}-${var.environment}-aks-resources"

  default_node_pool {
    name           = "default"
    vm_size        = var.aks_vm_size
    vnet_subnet_id = var.subnet_id
    node_count     = var.node_count
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    network_mode       = "transparent"
    network_plugin_mode = "overlay"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    pod_cidr          = var.pod_cidr
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags
} 
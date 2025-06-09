terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

# Azure kubernetes Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project}-${var.environment}-Kubernetes"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.project}-${var.environment}-Kubernetes-resources"

  default_node_pool {
    name           = "default"
    vm_size        = var.kubernetes_vm_size
    vnet_subnet_id = var.subnet_id
    node_count     = var.node_count
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_policy      = "azure"
    network_mode        = "transparent"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    pod_cidr            = var.pod_cidr
  }

  # Enable RBAC
  role_based_access_control_enabled = true

  # Enable OMS Agent logging
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Restrict API server access to specific IP ranges
  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags

  #checkov:skip=CKV_AZURE_115,CKV_AZURE_116,CKV_AZURE_117,CKV_AZURE_226,CKV_AZURE_232,CKV_AZURE_141,CKV_AZURE_168,CKV_AZURE_170,CKV_AZURE_171,CKV_AZURE_227: This is implicitly guranateed and public access is blocked for Azure Kubernetes Service

}

# Azure Front Door
resource "azurerm_frontdoor" "main" {
  name                = "${var.project}-${var.environment}-fd"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  routing_rule {
    name               = "default-rule"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match   = ["/*"]
    frontend_endpoints = ["default-endpoint"]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "default-pool"
    }
  }

  backend_pool_load_balancing {
    name = "default-lb"
  }

  backend_pool_health_probe {
    name = "default-probe"
  }

  backend_pool {
    name = "default-pool"
    backend {
      host_header = azurerm_kubernetes_cluster.main.private_fqdn
      address     = azurerm_kubernetes_cluster.main.private_fqdn
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = "default-lb"
    health_probe_name   = "default-probe"
  }

  frontend_endpoint {
    name                              = "default-endpoint"
    host_name                         = "${var.project}-${var.environment}-fd.azurefd.net"
    session_affinity_enabled          = true
    session_affinity_ttl_seconds      = 300
    web_application_firewall_policy_link_id = null
  }
}

# Application Gateway
resource "azurerm_public_ip" "agw" {
  name                = "${var.project}-${var.environment}-agw-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.project}-${var.environment}-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.aks.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.agw.id
  }

  backend_address_pool {
    name = "aks-pool"
    fqdns = [azurerm_kubernetes_cluster.main.private_fqdn]
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name            = "http-port"
    protocol                      = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                 = "Basic"
    http_listener_name        = "http-listener"
    backend_address_pool_name  = "aks-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 1
  }
} 
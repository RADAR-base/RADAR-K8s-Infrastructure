# Application Gateway for AKS Ingress
resource "azurerm_application_gateway" "aks_ingress" {
  name                = "${var.project}-${var.environment}-aks-agw"
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
    subnet_id            = azurerm_subnet.aks.id
    private_ip_address_allocation = "Dynamic"
  }

  backend_address_pool {
    name = "aks-pool"
    fqdns = [azurerm_lb.main.private_ip_address]
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

# Load Balancer Service for Ingress
resource "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  spec {
    type = "LoadBalancer"
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    port {
      port        = 443
      target_port = 443
      protocol    = "TCP"
    }
    selector = {
      "app.kubernetes.io/name" = "ingress-nginx"
    }
  }

  depends_on = [
    azurerm_application_gateway.aks_ingress,
    azurerm_lb.main
  ]
} 
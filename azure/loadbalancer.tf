# Public IP for Load Balancer
resource "azurerm_public_ip" "lb" {
  name                = "${var.project}-${var.environment}-lb-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# Load Balancer
resource "azurerm_lb" "main" {
  name                = "${var.project}-${var.environment}-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  tags                = local.tags

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.project}-${var.environment}-backend-pool"
  loadbalancer_id = azurerm_lb.main.id
}

# Health Probe
resource "azurerm_lb_probe" "http" {
  name            = "${var.project}-${var.environment}-http-probe"
  loadbalancer_id = azurerm_lb.main.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
  interval_in_seconds = 15
  number_of_probes   = 2
}

# Load Balancing Rule for HTTP
resource "azurerm_lb_rule" "http" {
  name                           = "${var.project}-${var.environment}-http-rule"
  loadbalancer_id                = azurerm_lb.main.id
  frontend_ip_configuration_name = "frontend-ip-config"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# Load Balancing Rule for HTTPS
resource "azurerm_lb_rule" "https" {
  name                           = "${var.project}-${var.environment}-https-rule"
  loadbalancer_id                = azurerm_lb.main.id
  frontend_ip_configuration_name = "frontend-ip-config"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.http.id
} 
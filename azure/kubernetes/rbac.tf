# AKS 到 ACR 的角色分配
resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name            = "AcrPull"
  scope                           = var.acr_id
  skip_service_principal_aad_check = true
} 
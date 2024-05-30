resource "helm_release" "metrics_server" {
  count = var.enable_metrics ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.metrics_server_version

  set {
    name  = "apiService.insecureSkipTLSVerify"
    value = "true"
  }

  wait = true
}

output "metrics_server_metadata" {
  value = var.enable_metrics ? helm_release.metrics_server[0].metadata : null
}

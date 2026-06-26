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

resource "kubernetes_namespace" "headlamp" {
  count = var.enable_metrics ? 1 : 0

  metadata {
    name = "headlamp"
  }
}

resource "helm_release" "headlamp" {
  count = var.enable_metrics ? 1 : 0

  name       = "headlamp"
  repository = "https://kubernetes-sigs.github.io/headlamp/"
  chart      = "headlamp"
  namespace  = kubernetes_namespace.headlamp[0].metadata[0].name
  version    = var.headlamp_version

  depends_on = [kubernetes_namespace.headlamp]
}

resource "kubernetes_service_account_v1" "headlamp_user" {
  count = var.enable_metrics ? 1 : 0

  metadata {
    name      = "headlamp-user"
    namespace = kubernetes_namespace.headlamp[0].metadata[0].name
  }

  depends_on = [
    helm_release.headlamp
  ]
}

resource "kubernetes_secret_v1" "headlamp_user" {
  count = var.enable_metrics ? 1 : 0

  metadata {
    name      = "headlamp-user-token"
    namespace = kubernetes_namespace.headlamp[0].metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.headlamp_user[0].metadata[0].name
    }
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true

  depends_on = [
    helm_release.headlamp
  ]
}

resource "kubernetes_cluster_role_binding_v1" "headlamp_user" {
  count = var.enable_metrics ? 1 : 0

  metadata {
    name = "headlamp-user"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.read_only[0].metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.headlamp_user[0].metadata[0].name
    namespace = kubernetes_namespace.headlamp[0].metadata[0].name
  }
  depends_on = [
    helm_release.headlamp,
    kubernetes_service_account_v1.headlamp_user
  ]
}

output "radar_base_headlamp_user_token" {
  value     = var.enable_metrics ? kubernetes_secret_v1.headlamp_user[0].data.token : null
  sensitive = true
}

resource "kubernetes_cluster_role_v1" "read_only" {
  count = var.enable_metrics ? 1 : 0

  metadata {
    name = "read-only-cluster-role"
  }

  rule {
    api_groups = [""]
    resources = [
      "bindings", "configmaps", "deployments", "endpoints", "events", "ingressclasses",
      "limitranges", "namespaces", "namespaces/status", "nodes", "persistentvolumeclaims", "persistentvolumes",
      "pods", "pods/log", "pods/status", "replicasets", "replicationcontrollers", "replicationcontrollers",
      "replicationcontrollers/scale", "replicationcontrollers/status", "resourcequotas", "resourcequotas/status",
      "secrets", "serviceaccounts", "services", "services",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["daemonsets", "deployments", "deployments/scale", "replicasets", "replicasets/scale", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs", "jobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources = [
      "daemonsets", "deployments", "deployments/scale", "ingresses", "networkpolicies",
      "replicasets", "replicasets/scale", "replicationcontrollers/scale",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "ingressclasses", "networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "volumeattachments"]
    verbs      = ["get", "list", "watch"]
  }
}

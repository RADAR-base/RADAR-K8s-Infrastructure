mock_provider "aws" {
  source = "./tests/mocks"
}

mock_provider "archive" {}
mock_provider "helm" {}
mock_provider "kubectl" {}
mock_provider "kubernetes" {}
mock_provider "random" {}

variables {
  eks_cluster_name = "radar-base-test"
  radar_postgres_password = "test"
  docker_hub_username     = "test"
  docker_hub_access_token = "test"
  ghcr_username           = "test"
  ghcr_access_token       = "test"
  domain_name = { "radar-base.test" = "Z0123456789ABCDEFGHIJ" }
  enable_metrics          = true
  enable_karpenter        = false
  enable_msk              = false
  enable_rds              = false
  enable_route53          = false
  enable_ses              = false
  enable_s3               = false
  enable_eip              = false
  enable_ecr_ptc          = false
  with_dmz_pods           = false
  ses_bounce_destinations = []

  AWS_ACCESS_KEY_ID       = "test"
  AWS_SECRET_ACCESS_KEY   = "test"
}

run "metrics_plans_the_full_graph" {
  command = plan

  assert {
    condition = alltrue([
      length(helm_release.metrics_server) == 1,
      length(kubernetes_namespace.headlamp) == 1,
      length(helm_release.headlamp) == 1,
      length(kubernetes_service_account_v1.headlamp_user) == 1,
      length(kubernetes_secret_v1.headlamp_user) == 1,
      length(kubernetes_cluster_role_binding_v1.headlamp_user) == 1,
      length(kubernetes_cluster_role_v1.read_only) == 1,
    ])
    error_message = "The enable_metrics should plan both charts plus the headlamp namespace, identity and RBAC objects"
  }
}

run "metrics_server_chart_uses_the_pinned_version" {
  command = plan

  assert {
    condition = alltrue([
      helm_release.metrics_server[0].name == "metrics-server",
      helm_release.metrics_server[0].chart == "metrics-server",
      helm_release.metrics_server[0].namespace == "kube-system",
      helm_release.metrics_server[0].repository == "https://kubernetes-sigs.github.io/metrics-server/",
      helm_release.metrics_server[0].version == var.metrics_server_version,
      helm_release.metrics_server[0].wait,
    ])
    error_message = "The metrics server chart should match, including the pinned version"
  }

  assert {
    condition = alltrue([
      for setting in helm_release.metrics_server[0].set : setting.name == "apiService.insecureSkipTLSVerify"
    ])
    error_message = "The only chart setting should be apiService.insecureSkipTLSVerify"
  }

  assert {
    condition = alltrue([
      for setting in helm_release.metrics_server[0].set : setting.value == "true"
    ])
    error_message = "apiService.insecureSkipTLSVerify should be set to the string \"true\""
  }
}

run "headlamp_chart_is_installed_into_its_own_namespace" {
  command = plan

  assert {
    condition = alltrue([
      helm_release.headlamp[0].name == "headlamp",
      helm_release.headlamp[0].chart == "headlamp",
      helm_release.headlamp[0].repository == "https://kubernetes-sigs.github.io/headlamp/",
      helm_release.headlamp[0].version == var.headlamp_version,
      kubernetes_namespace.headlamp[0].metadata[0].name == "headlamp",
    ])
    error_message = "Headlamp and its namespace should match"
  }

  assert {
    condition     = helm_release.headlamp[0].namespace == kubernetes_namespace.headlamp[0].metadata[0].name
    error_message = "The headlamp chart should be installed into the namespace created for it"
  }
}

run "headlamp_identity_objects_are_wired_together" {
  command = plan

  assert {
    condition = alltrue([
      kubernetes_service_account_v1.headlamp_user[0].metadata[0].name == "headlamp-user",
      kubernetes_service_account_v1.headlamp_user[0].metadata[0].namespace == "headlamp",
      kubernetes_secret_v1.headlamp_user[0].metadata[0].name == "headlamp-user-token",
      kubernetes_secret_v1.headlamp_user[0].type == "kubernetes.io/service-account-token",
      kubernetes_secret_v1.headlamp_user[0].wait_for_service_account_token,
    ])
    error_message = "The headlamp service account and token secret should match"
  }

  assert {
    condition     = kubernetes_secret_v1.headlamp_user[0].metadata[0].annotations["kubernetes.io/service-account.name"] == kubernetes_service_account_v1.headlamp_user[0].metadata[0].name
    error_message = "The token secret should be annotated with the headlamp service account name"
  }

  assert {
    condition = alltrue([
      kubernetes_cluster_role_binding_v1.headlamp_user[0].metadata[0].name == "headlamp-user",
      kubernetes_cluster_role_binding_v1.headlamp_user[0].role_ref[0].name == kubernetes_cluster_role_v1.read_only[0].metadata[0].name,
      kubernetes_cluster_role_binding_v1.headlamp_user[0].role_ref[0].kind == "ClusterRole",
      kubernetes_cluster_role_binding_v1.headlamp_user[0].subject[0].name == kubernetes_service_account_v1.headlamp_user[0].metadata[0].name,
      kubernetes_cluster_role_binding_v1.headlamp_user[0].subject[0].namespace == "headlamp",
    ])
    error_message = "The binding should reference the read-only ClusterRole and the headlamp service account"
  }
}

run "read_only_cluster_role_grants_only_read_verbs" {
  command = plan

  assert {
    condition     = kubernetes_cluster_role_v1.read_only[0].metadata[0].name == "read-only-cluster-role"
    error_message = "The read-only role should be named read-only-cluster-role"
  }

  assert {
    condition = alltrue([
      for rule in kubernetes_cluster_role_v1.read_only[0].rule : toset(rule.verbs) == toset(["get", "list", "watch"])
    ])
    error_message = "Every rule must grant only get, list and watch"
  }

  assert {
    condition = alltrue([
      for rule in kubernetes_cluster_role_v1.read_only[0].rule :
      alltrue([for verb in rule.verbs : !contains(["create", "update", "patch", "delete", "deletecollection", "*"], lower(verb))])
    ])
    error_message = "No rule may grant a mutating or wildcard verb"
  }

  assert {
    condition = alltrue([
      for rule in kubernetes_cluster_role_v1.read_only[0].rule : length(rule.api_groups) == 1
    ])
    error_message = "Every rule should target exactly one API group"
  }

  assert {
    condition = alltrue([
      for rule in kubernetes_cluster_role_v1.read_only[0].rule :
      contains([
        "", "apps", "autoscaling", "batch", "extensions", "networking.k8s.io",
        "policy", "rbac.authorization.k8s.io", "storage.k8s.io",
      ], rule.api_groups[0])
    ])
    error_message = "The read-only role should only cover the documented API groups"
  }

  assert {
    condition = contains(
      flatten([for rule in kubernetes_cluster_role_v1.read_only[0].rule : rule.resources]),
      "secrets",
    )
    error_message = "The read-only role should be able to read secrets"
  }
}

run "disabling_metrics_removes_every_metrics_resource" {
  command = plan

  variables {
    enable_metrics = false
  }

  assert {
    condition = alltrue([
      length(helm_release.metrics_server) == 0,
      length(helm_release.headlamp) == 0,
      length(kubernetes_namespace.headlamp) == 0,
      length(kubernetes_service_account_v1.headlamp_user) == 0,
      length(kubernetes_secret_v1.headlamp_user) == 0,
      length(kubernetes_cluster_role_binding_v1.headlamp_user) == 0,
      length(kubernetes_cluster_role_v1.read_only) == 0,
      output.radar_base_headlamp_user_token == null,
    ])
    error_message = "Turning enable_metrics off should remove every metrics and headlamp resource"
  }
}

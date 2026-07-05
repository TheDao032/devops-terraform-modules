# locals {
#   traefik_rbac_value_file = "${path.module}/templates/traefik_rbac.yml.tftpl"
#   traefik_sac_name        = "terraform-traefik"
#   traefik_namespace       = "kube-system"
# }
#
# resource "kubectl_manifest" "traefik_rbac" {
#   yaml_body = templatefile(
#     local.traefik_rbac_value_file,
#     {
#       namespace = local.traefik_namespace
#       service_account_name = local.traefik_sac_name
#     }
#   )
# }

resource "kubernetes_service_account" "traefik_sa" {
  metadata {
    name      = "terraform-traefik"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role" "traefik_manager" {
  metadata {
    name = "terraform-traefik-manager"
  }
  rule {
    api_groups = ["traefik.containo.us"]
    resources  = ["middlewares"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "traefik_manager_binding" {
  metadata {
    name = "terraform-traefik-manager-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.traefik_manager.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.traefik_sa.metadata[0].name
    namespace = kubernetes_service_account.traefik_sa.metadata[0].namespace
  }
}

resource "kubernetes_secret" "traefik_sa_token" {
  metadata {
    name      = "${kubernetes_service_account.traefik_sa.metadata[0].name}-token"
    namespace = kubernetes_service_account.traefik_sa.metadata[0].namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.traefik_sa.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

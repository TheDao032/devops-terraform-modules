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

# for_each over the rbacs MAP (keyed by name, e.g. "traefik") — NOT count. var.rbacs is an
# object/map, so numeric indexing (var.rbacs[count.index]) is invalid; each.key/each.value give
# name-stable addresses (…["traefik"]) so adding/removing an entry doesn't churn the others.
# An empty map ({}) yields zero resources, so no length() guard is needed.
resource "kubernetes_service_account_v1" "sa" {
  for_each = var.rbacs

  metadata {
    name      = each.value.sa.metadata.name
    namespace = each.value.sa.metadata.namespace
  }
}

resource "kubernetes_cluster_role_v1" "manager" {
  for_each = var.rbacs
  metadata {
    name = each.value.cluster_role.metadata.name
  }
  rule {
    api_groups = each.value.cluster_role.rule.api_groups
    resources  = each.value.cluster_role.rule.resources
    verbs      = each.value.cluster_role.rule.verbs
  }
}

resource "kubernetes_cluster_role_binding_v1" "manager_binding" {
  for_each = var.rbacs
  metadata {
    name = each.value.cluster_role_binding.metadata.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.manager[each.key].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.sa[each.key].metadata[0].name
    namespace = kubernetes_service_account_v1.sa[each.key].metadata[0].namespace
  }
}

resource "kubernetes_secret_v1" "sa_token" {
  for_each = var.rbacs
  metadata {
    name      = "${kubernetes_service_account_v1.sa[each.key].metadata[0].name}-token"
    namespace = kubernetes_service_account_v1.sa[each.key].metadata[0].namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.sa[each.key].metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

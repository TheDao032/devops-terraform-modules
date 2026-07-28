locals {
  # Split the vendored operator manifest (Deployment + RBAC + SA + Service) into single docs,
  # keyed by kind/namespace/name so the map is stable across plans.
  operator_file = "${path.module}/files/${var.operator_manifest_file}"
  operator_doc_list = [
    for d in split("\n---\n", file(local.operator_file)) : trimspace(d)
    if trimspace(d) != "" && can(regex("(?m)^kind:", trimspace(d)))
  ]
  operator_docs = var.enabled == 1 ? {
    for d in local.operator_doc_list :
    "${yamldecode(d).kind}/${try(yamldecode(d).metadata.namespace, "cluster")}/${yamldecode(d).metadata.name}" => d
  } : {}
}

# Namespace first (the operator manifest's namespaced resources target it).
resource "kubectl_manifest" "namespace" {
  count = var.enabled

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata   = { name = var.namespace }
  })
}

# Keycloak Operator (Deployment + RBAC + ServiceAccount + Service). Server-side apply — some of
# these (ClusterRoles) are large; force_conflicts so re-apply adopts fields cleanly.
resource "kubectl_manifest" "operator" {
  for_each = local.operator_docs

  yaml_body         = each.value
  server_side_apply = true
  force_conflicts   = true
  wait              = true

  depends_on = [kubectl_manifest.namespace]
}

# DB credentials Secret the Keycloak CR references (usernameSecret/passwordSecret). Values come
# from Vault via the terragrunt vault-secrets dependency (same flow as the database/ units).
resource "kubectl_manifest" "db_secret" {
  count = var.enabled

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    type       = "Opaque"
    metadata   = { name = "keycloak-db", namespace = var.namespace }
    stringData = { username = var.db_username, password = var.db_password }
  })

  depends_on = [kubectl_manifest.namespace]
}

# The Keycloak instance. Requires the CRDs (installed cluster-once by init-resources' crds
# module) + the operator running + the DB Secret. NOTE cross-stack ordering: apply
# init-resources (CRDs) BEFORE this ops-tools stack, or the CR kind won't be registered yet.
resource "kubectl_manifest" "keycloak" {
  count = var.enabled

  yaml_body = templatefile("${path.module}/templates/keycloak-cr.yml.tftpl", {
    name      = "keycloak"
    namespace = var.namespace
    conf      = var.keycloak_conf
  })

  server_side_apply = true
  force_conflicts   = true

  depends_on = [
    kubectl_manifest.operator,
    kubectl_manifest.db_secret,
  ]
}

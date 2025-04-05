locals {
  # helm_app_file = "${path.module}/apps/${var.namespace}/application.helm.yml.tmpl"
  # app_created   = fileexists(local.helm_app_file) ? var.enabled : 0

  secret_store_value_file = "${path.module}/namespaces/${var.namespace}/secret-store.yml.tmpl"
  secret_store_created    = fileexists(local.secret_store_value_file) ? var.enabled : 0

  vault_secret_value_file = "${path.module}/namespaces/${var.namespace}/vault-token.yml.tmpl"
  vault_secret_created    = fileexists(local.vault_secret_value_file) ? var.enabled : 0

  namespace_value_file = "${path.module}/namespaces/${var.namespace}/namespace.yml.tmpl"
  namespace_created    = fileexists(local.namespace_value_file) ? var.enabled : 0

  # templates_path    = "${path.module}/apps/${var.name}/templates"
  # templates         = fileset(local.templates_path, "*.yml.tmpl")
  # templates_enabled = length(local.templates) > 0 ? length(local.templates) : 0

  # serviceaccount_file = "${path.module}/charts/${var.name}/serviceaccount.json"
  # iam_role_created    = fileexists(local.serviceaccount_file) ? var.enabled : 0
}

# resource "kubernetes_namespace" "namespace" {
#   metadata {
#     annotations = {
#       name = var.namespace
#     }
#
#     labels = {
#       name = var.namespace
#     }
#
#     name = var.namespace
#   }
# }

resource "kubectl_manifest" "namespace" {
  count = local.namespace_created

  yaml_body = templatefile(local.namespace_value_file, {
    namespace = var.namespace
  })
}

resource "kubectl_manifest" "vault_token_secret" {
  count = local.vault_secret_created

  yaml_body = templatefile(local.vault_secret_value_file, {
    parameters  = var.parameters
    namespace   = var.namespace
    environment = var.environment
  })

  depends_on = [kubectl_manifest.namespace]
}

resource "kubectl_manifest" "secret_store" {
  count = local.secret_store_created

  yaml_body = templatefile(local.secret_store_value_file, {
    parameters  = var.parameters
    namespace   = var.namespace
    environment = var.environment
  })

  depends_on = [kubectl_manifest.vault_token_secret]
}


# resource "kubectl_manifest" "main" {
#   count = local.app_created
#
#   yaml_body = templatefile(local.helm_app_file, {
#     parameters  = var.parameters
#     namespace   = var.namespace
#     environment = var.environment
#   })
#
#   depends_on = [kubectl_manifest.namespace]
# }

# resource "kubectl_manifest" "templates" {
#   for_each = var.enabled == 1 ? toset(local.templates) : toset([])
#   # for_each = toset(local.templates)
#
#   yaml_body = templatefile("${local.templates_path}/${each.value}", {
#     parameters  = var.parameters
#     namespace   = var.namespace
#     environment = var.environment
#   })
#
#   depends_on = [kubectl_manifest.main]
# }

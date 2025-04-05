locals {
  value_file = "${path.module}/charts/${var.name}/values.yml.tmpl"
  chart      = var.chart == null ? null : "${path.module}/charts/${var.name}"

  sc_value_file = "${path.module}/charts/${var.name}/sc.yml.tmpl"
  sc_created    = fileexists(local.sc_value_file) ? var.enabled : 0

  # secret_store_value_file = "${path.module}/charts/${var.name}/secret-store.yml.tmpl"
  # secret_store_created    = fileexists(local.secret_store_value_file) ? var.enabled : 0
  #
  # vault_secret_value_file = "${path.module}/charts/${var.name}/vault-token.yml.tmpl"
  # vault_secret_created    = fileexists(local.vault_secret_value_file) ? var.enabled : 0

  templates_path = "${path.module}/charts/${var.name}/templates"
  templates      = fileset(local.templates_path, "*.yml.tmpl")
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

resource "kubectl_manifest" "sc" {
  count = local.sc_created

  yaml_body = templatefile(local.sc_value_file, {
    sc_name   = var.parameters.common.sc_name
    namespace = var.namespace
  })
}

# resource "kubectl_manifest" "vault_token_secret" {
#   count = local.vault_secret_created
#
#   yaml_body = templatefile(local.vault_secret_value_file, {
#     parameters  = var.parameters
#     namespace   = var.namespace
#     environment = var.environment
#   })
# }
#
# resource "kubectl_manifest" "secret_store" {
#   count = local.secret_store_created
#
#   yaml_body = templatefile(local.secret_store_value_file, {
#     parameters  = var.parameters
#     namespace   = var.namespace
#     environment = var.environment
#   })
#
#   depends_on = [kubectl_manifest.vault_token_secret]
# }


resource "helm_release" "main" {
  count            = var.enabled
  name             = var.name
  repository       = var.repository
  version          = var.chart_version
  namespace        = var.namespace
  chart            = coalesce(local.chart, var.name)
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.value_file) ?
    [
      templatefile(
        local.value_file,
        {
          namespace   = var.namespace
          environment = var.environment
          parameters  = var.parameters
        },
      )
  ] : null)

  # Wait until all resources are ready
  wait          = true
  wait_for_jobs = true

  depends_on = [kubectl_manifest.sc]
}

resource "kubectl_manifest" "templates" {
  for_each = var.enabled == 1 ? toset(local.templates) : toset([])
  # for_each = toset(local.templates)

  yaml_body = templatefile("${local.templates_path}/${each.value}", {
    parameters  = var.parameters
    namespace   = var.namespace
    environment = var.environment
  })

  depends_on = [
    helm_release.main,
    # kubectl_manifest.secret_store
  ]
}

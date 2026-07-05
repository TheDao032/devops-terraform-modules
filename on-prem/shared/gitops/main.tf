locals {
  helm_app_file = "${path.module}/apps/${var.name}/application.helm.yml.tftpl"
  app_created   = fileexists(local.helm_app_file) ? var.enabled : 0

  ex_secret_value_file = "${path.module}/apps/${var.name}/ex-secrets.yml.tftpl"
  ex_secret_created    = fileexists(local.ex_secret_value_file) ? var.enabled : 0

  namespace_value_file = "${path.module}/apps/${var.name}/namespace.yml.tftpl"
  namespace_created    = fileexists(local.namespace_value_file) ? var.enabled : 0

  # templates_path    = "${path.module}/apps/${var.name}/templates"
  # templates         = fileset(local.templates_path, "*.yml.tftpl")
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

# resource "kubectl_manifest" "namespace" {
#   count = local.namespace_created
#
#   yaml_body = templatefile(local.namespace_value_file, {
#     environment = var.environment
#   })
# }

resource "kubectl_manifest" "ex_secret" {
  count = local.ex_secret_created

  yaml_body = templatefile(local.ex_secret_value_file, {
    parameters  = var.parameters
    namespace   = var.namespace
    environment = var.environment
  })

  # depends_on = [kubectl_manifest.namespace]
}

resource "kubectl_manifest" "main" {
  count = local.app_created

  yaml_body = templatefile(local.helm_app_file, {
    parameters  = var.parameters
    namespace   = var.namespace
    environment = var.environment
  })

  depends_on = [kubectl_manifest.ex_secret]
}

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

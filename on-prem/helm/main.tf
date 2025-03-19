locals {
  value_file = "${path.module}/charts/${var.name}/values.yml.tftpl"
  chart      = var.chart == null ? null : "${path.module}/charts/${var.name}"

  sc_value_file = "${path.module}/charts/${var.name}/templates/sc.yml.tftpl"
  sc_created    = fileexists(local.sc_value_file) ? var.enabled : 0

  # serviceaccount_file = "${path.module}/charts/${var.name}/serviceaccount.json"
  # iam_role_created    = fileexists(local.serviceaccount_file) ? var.enabled : 0
}

resource "kubectl_manifest" "sc" {
  count = local.sc_created

  yaml_body = templatefile(local.sc_value_file, {
    sc_name   = var.parameters.values.sc_name
    namespace = var.namespace
  })
}

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
          parameters = var.parameters
        },
      )
  ] : null)
}

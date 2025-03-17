locals {
  value_file = "${path.module}/charts/${var.name}/values.yml.tftpl"
  chart      = var.chart == null ? null : "${path.module}/charts/${var.name}"

  # serviceaccount_file = "${path.module}/charts/${var.name}/serviceaccount.json"
  # iam_role_created    = fileexists(local.serviceaccount_file) ? var.enabled : 0
}

resource "helm_release" "main" {
  count            = var.enabled
  name             = var.release_name
  repository       = var.repository
  version          = var.chart_version
  namespace        = var.namespace
  chart            = local.chart
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

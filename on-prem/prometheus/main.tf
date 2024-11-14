locals {
  value_file         = "${path.module}/values.yml.tmpl"
}

resource "helm_release" "main" {
  name             = var.helm_release_name
  namespace        = var.namespace
  repository       = var.helm_repository
  version          = var.chart_version
  chart            = var.helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.value_file) ?
    [
      templatefile(
        local.value_file,
        {
        alertmanager   = var.alertmanager,
        prometheus     = var.prometheus,
        grafana        = var.grafana,
        },
      )
  ] : null)
}

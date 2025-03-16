locals {
  value_file   = "${path.module}/argocd/templates/values/values.yml.tftpl"
  argocd_chart = var.argocd_conf.chart_info
}

resource "helm_release" "argocd" {
  name             = local.argocd_chart.helm_release_name
  namespace        = local.argocd_chart.namespace
  repository       = local.argocd_chart.helm_repository
  version          = local.argocd_chart.chart_version
  chart            = local.argocd_chart.helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.value_file) ?
    [
      templatefile(
        local.value_file,
        merge(
          var.parameters, {},
        )
      )
  ] : null)
}

locals {
  value_file         = "${path.module}/values.yml.tmpl"
}

resource "helm_release" "main" {
  name             = "prometheus-community"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  version          = var.chart_version
  chart            = "kube-prometheus-stack"
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.value_file) ?
    [
      templatefile(
        local.value_file,
        {
          alertmanager_host   = var.alertmanager_inrgess.host,
          alertmanager_prefix = var.alertmanager_inrgess.prefix,
          prometheus_host     = var.prometheus_inrgess.host,
          prometheus_prefix   = var.prometheus_inrgess.prefix,
          grafana_host        = var.grafana_inrgess.host,
          grafana_prefix      = var.grafana_inrgess.prefix
        },
      )
  ] : null)
}

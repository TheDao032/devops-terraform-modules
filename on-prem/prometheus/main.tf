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
          alertmanager   = var.alertmanager_ingress,
          prometheus     = var.prometheus_ingress,
          grafana        = var.grafana_ingress,
        },
      )
  ] : null)
}

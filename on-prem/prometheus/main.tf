locals {
  value_file            = "${path.module}/values.yml.tftpl"
  traefik_ingroute_file = "${path.module}/templates/ings/traefik_ingroute.yml.tftpl"
  traefik_middle_file   = "${path.module}/templates/middlewares/traefik_middle.yml.tftpl"
  traefik_namespace     = "kube-system"

  prometheus_svc_prefix = "kube-prometheus"

  prometheus_middleware_list = {
    grafana = {
      name = var.grafana.ingress.strip_prefix
      prefixes = [
        "/grafana"
      ]
      namespace = var.namespace
    }
    prometheus = {
      name = var.prometheus.ingress.strip_prefix
      prefixes = [
        "/prometheus"
      ]
      namespace = var.namespace
    }
    alertmanager = {
      name = var.alertmanager.ingress.strip_prefix
      prefixes = [
        "/alertmanager"
      ]
      namespace = var.namespace
    }
  }

  prometheus_ingressroute_list = {
    grafana = {
      ingress_route_name     = "grafana-ingressroute"
      middleware_annotations = "${var.namespace}-${var.grafana.ingress.strip_prefix}@kubernetescrd"
      match_condition        = "Host(`${var.external_server_ip}`) && PathPrefix(`${var.grafana.ingress.prefix}`)"
      middlewares = [
        {
          name      = var.grafana.ingress.strip_prefix
          namespace = var.namespace
        }
      ]
      services = [
        {
          name      = "${var.helm_release_name}-grafana"
          port      = 80
          namespace = var.namespace
        }
      ]
      namespace = var.namespace
    }

    prometheus = {
      ingress_route_name     = "prometheus-ingressroute"
      middleware_annotations = "${var.namespace}-${var.prometheus.ingress.strip_prefix}@kubernetescrd"
      match_condition        = "Host(`${var.external_server_ip}`) && PathPrefix(`${var.prometheus.ingress.prefix}`)"
      middlewares = [
        {
          name      = var.prometheus.ingress.strip_prefix
          namespace = var.namespace
        }
      ]
      services = [
        {
          name      = "${var.helm_release_name}-${local.prometheus_svc_prefix}-prometheus"
          port      = 9090
          namespace = var.namespace
        }
      ]
      namespace = var.namespace
    }
    alertmanager = {
      ingress_route_name     = "alertmanager-ingressroute"
      middleware_annotations = "${var.namespace}-${var.alertmanager.ingress.strip_prefix}@kubernetescrd"
      match_condition        = "Host(`${var.external_server_ip}`) && PathPrefix(`${var.alertmanager.ingress.prefix}`)"
      middlewares = [
        {
          name      = var.alertmanager.ingress.strip_prefix
          namespace = var.namespace
        }
      ]
      services = [
        {
          name      = "${var.helm_release_name}-${local.prometheus_svc_prefix}-alertmanager"
          port      = 9093
          namespace = var.namespace
        }
      ]
      namespace = var.namespace
    }
  }

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
          alertmanager       = var.alertmanager,
          prometheus         = var.prometheus,
          grafana            = var.grafana,
          external_server_ip = var.external_server_ip
        },
      )
  ] : null)
}

resource "kubectl_manifest" "traefik_middle" {
  for_each = local.prometheus_middleware_list

  yaml_body = templatefile(local.traefik_middle_file,
    {
      name      = each.value.name
      prefixes  = each.value.prefixes
      namespace = each.value.namespace
    }
  )

  depends_on = [helm_release.main]
}

resource "kubectl_manifest" "traefik_ingressroute" {
  for_each = local.prometheus_ingressroute_list
  yaml_body = templatefile(local.traefik_ingroute_file,
    {
      ingress_route_name     = each.value.ingress_route_name
      middleware_annotations = each.value.middleware_annotations
      match_condition        = each.value.match_condition
      middlewares            = each.value.middlewares
      services               = each.value.services
      namespace              = each.value.namespace
    }
  )

  depends_on = [kubectl_manifest.traefik_middle]
}

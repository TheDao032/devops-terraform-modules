locals {
  loki_value_file         = "${path.module}/templates/values/values.loki.monolithic.yml.tftpl"
  alloy_value_file        = "${path.module}/templates/values/values.alloy.yml.tftpl"
  loki_sc_value_file      = "${path.module}/templates/storage-classes/sc.loki.yml.tftpl"
  loki_storage_class_name = "loki-sc"

  traefik_ingroute_file = "${path.module}/templates/ings/traefik_ingroute.yml.tftpl"
  traefik_middle_file   = "${path.module}/templates/middlewares/traefik_middle.yml.tftpl"

  middleware_list = [
    {
      name = var.loki_conf.loki_ingress.strip_prefix
      prefixes = [
        var.loki_conf.loki_ingress.prefix
      ]
      namespace = var.namespace
    },
  ]

  ingressroute_list = {
    loki = {
      ingress_route_name = "loki-ingressroute"
      match_condition    = "PathPrefix(`${var.loki_conf.loki_ingress.prefix}`)"
      middlewares = flatten([for middleware in local.middleware_list : {
        name      = middleware.name
        namespace = middleware.namespace
      }])
      services = [
        {
          name      = var.loki_helm_release_name
          port      = 3100
          namespace = var.namespace
        }
      ]
      middleware_annotations = join(", ", [for middleware in local.middleware_list : "${var.namespace}-${middleware.name}@kubernetescrd"])
      namespace              = var.namespace
    }
  }
}

resource "kubectl_manifest" "loki_storage_class" {
  yaml_body = templatefile(local.loki_sc_value_file, {
    storage_class_name = local.loki_storage_class_name
    namespace          = var.namespace
  })
}

resource "helm_release" "loki" {
  name             = var.loki_helm_release_name
  namespace        = var.namespace
  repository       = var.helm_repository
  version          = var.loki_chart_version
  chart            = var.loki_helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.loki_value_file) ?
    [
      templatefile(
        local.loki_value_file,
        {
          loki_conf     = var.loki_conf
          storage_class = local.loki_storage_class_name
        }
      )
  ] : null)

  depends_on = [kubectl_manifest.loki_storage_class]
}

resource "helm_release" "alloy" {
  name             = var.alloy_helm_release_name
  namespace        = var.namespace
  repository       = var.helm_repository
  version          = var.alloy_chart_version
  chart            = var.alloy_helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.alloy_value_file) ?
    [
      templatefile(
        local.alloy_value_file,
        {
          alloy_conf = var.alloy_conf
        }
      )
  ] : null)
}

resource "kubectl_manifest" "loki_traefik_middle" {
  count = length(local.middleware_list)

  yaml_body = templatefile(local.traefik_middle_file,
    {
      name      = local.middleware_list[count.index].name
      prefixes  = local.middleware_list[count.index].prefixes
      namespace = local.middleware_list[count.index].namespace
    }
  )

  depends_on = [helm_release.loki]
}

resource "kubectl_manifest" "loki_traefik_ingressroute" {
  for_each = local.ingressroute_list
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

  depends_on = [kubectl_manifest.loki_traefik_middle]
}

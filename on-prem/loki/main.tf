locals {
  monolithic_loki_value_file   = "${path.module}/templates/values/values.loki.monolithic.yml.tftpl"
  microservice_loki_value_file = "${path.module}/templates/values/values.loki.microservice.yml.tftpl"
  scalable_loki_value_file     = "${path.module}/templates/values/values.loki.scalable.yml.tftpl"
  alloy_value_file             = "${path.module}/templates/values/values.alloy.yml.tftpl"
  loki_sc_value_file           = "${path.module}/templates/storage-classes/sc.loki.yml.tftpl"
  loki_storage_class_name      = "loki-sc"

  traefik_ingroute_file = "${path.module}/templates/ings/traefik_ingroute.yml.tftpl"
  traefik_middle_file   = "${path.module}/templates/middlewares/traefik_middle.yml.tftpl"

  middleware_list = [
    {
      name = var.common_conf.ingress.strip_prefix
      prefixes = [
        var.common_conf.ingress.prefix
      ]
      namespace = var.namespace
    },
  ]

  ingressroute_list = {
    loki = {
      ingress_route_name = "loki-ingressroute"
      match_condition    = "PathPrefix(`${var.common_conf.ingress.prefix}`)"
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

resource "helm_release" "microservice_loki" {
  name             = var.loki_helm_release_name
  namespace        = var.namespace
  repository       = var.helm_repository
  version          = var.loki_chart_version
  chart            = var.loki_helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.microservice_loki_value_file) ?
    [
      templatefile(
        local.microservice_loki_value_file,
        {
          common_conf   = var.common_conf
          loki_conf     = var.microservice_conf
          auth_conf     = var.auth_conf
          storage_class = local.loki_storage_class_name
        }
      )
  ] : null)

  depends_on = [kubectl_manifest.loki_storage_class]
}

# resource "helm_release" "monolithic_loki" {
#   name             = var.loki_helm_release_name
#   namespace        = var.namespace
#   repository       = var.helm_repository
#   version          = var.loki_chart_version
#   chart            = var.loki_helm_release_chart
#   create_namespace = true
#   upgrade_install  = true
#   values = (fileexists(local.monolithic_loki_value_file) ?
#     [
#       templatefile(
#         local.monolithic_loki_value_file,
#         {
#           loki_conf     = var.monolithic_conf
#           storage_class = local.loki_storage_class_name
#         }
#       )
#   ] : null)
#
#   depends_on = [kubectl_manifest.loki_storage_class]
# }
#
# resource "helm_release" "scalable_loki" {
#   name             = var.loki_helm_release_name
#   namespace        = var.namespace
#   repository       = var.helm_repository
#   version          = var.loki_chart_version
#   chart            = var.loki_helm_release_chart
#   create_namespace = true
#   upgrade_install  = true
#   values = (fileexists(local.scalable_loki_value_file) ?
#     [
#       templatefile(
#         local.scalable_loki_value_file,
#         {
#           loki_conf     = var.scalable_conf
#           storage_class = local.loki_storage_class_name
#         }
#       )
#   ] : null)
#
#   depends_on = [kubectl_manifest.loki_storage_class]
# }

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
          alloy_conf     = var.alloy_conf
          loki_auth_conf = var.auth_conf
          loki_url       = "${var.loki_helm_release_name}-distributor.${var.namespace}.svc.cluster.local:3100"
          cluster_name   = var.cluster_name
        }
      )
  ] : null)

  depends_on = [helm_release.microservice_loki]
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

  depends_on = [helm_release.microservice_loki]
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

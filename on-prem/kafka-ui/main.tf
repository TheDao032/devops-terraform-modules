locals {
  value_file            = "${path.module}/values.yml.tftpl"
  traefik_ingroute_file = "${path.module}/templates/ings/traefik_ingroute.yml.tftpl"
  traefik_middle_file   = "${path.module}/templates/middlewares/traefik_middle.yml.tftpl"

  middleware_strip_prefix_list = [
    {
      name      = var.kafka_ui_conf.ingress.strip_prefix
      prefixes  = [var.kafka_ui_conf.ingress.prefix]
      namespace = var.namespace
    },
  ]

  middleware_combined_list = concat(
    local.middleware_strip_prefix_list,
  )

  ingressroute_list = {
    kafka_ui = {
      ingress_route_name = "kafka-ui-ingressroute"
      match_condition    = "PathPrefix(`${var.kafka_ui_conf.ingress.prefix}`)"
      namespace          = var.namespace
      services = [
        {
          name      = var.helm_release_name
          port      = 80
          namespace = var.namespace
        }
      ]

      middleware_annotations = join(",", [for middleware in local.middleware_combined_list : "${var.namespace}-${middleware.name}@kubernetescrd"])
      middlewares = flatten([for middleware in local.middleware_combined_list : {
        name      = middleware.name
        namespace = middleware.namespace
      }])
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
        local.value_file, {
          image_tag                      = var.image_tag
          kafka_ui_conf                  = var.kafka_ui_conf
          keycloak                       = var.keycloak_kafka_ui_credentials
          internal_bootstrap_server      = var.internal_bootstrap_server
          internal_bootstrap_server_port = var.internal_bootstrap_server_port
          environment                    = var.environment
        }
      )
  ] : null)
}

resource "kubectl_manifest" "traefik_middle_strip_prefix" {
  count = length(local.middleware_strip_prefix_list)

  yaml_body = templatefile(local.traefik_middle_file,
    {
      name      = local.middleware_strip_prefix_list[count.index].name
      prefixes  = local.middleware_strip_prefix_list[count.index].prefixes
      namespace = local.middleware_strip_prefix_list[count.index].namespace
    }
  )

  depends_on = [helm_release.main]
}

resource "kubectl_manifest" "traefik_ingressroute" {
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

  depends_on = [
    kubectl_manifest.traefik_middle_strip_prefix,
  ]
}

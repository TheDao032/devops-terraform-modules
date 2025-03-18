locals {
  traefik_gc_file                    = "${path.module}/templates/traefik/gc/traefik_gc.yml.tftpl"
  traefik_dashboard_gateway_api_file = "${path.module}/templates/traefik/gateway-api/dashboard_gatewap_api.yml.tftpl"
  traefik_gw_file                    = "${path.module}/templates/traefik/gateway-api/gatewap.yml.tftpl"
  traefik_gc_name                    = "traefik"
  traefik_gw_name                    = "traefik"

  # traefik_dashboard_svc_value_file      = ""
  # traefik_dashboard_ing_value_file      = ""
}

# resource "kubectl_manifest" "traefik_dashboard_svc" {
#   yaml_body = templatefile(
#     local.traefik_dashboard_svc_value_file,
#     {
#       traefik_host       = "traefik.local.nthedao.info"
#       ingress_route_name = var.traefik_dashboard_ingress_route_name
#       namespace          = var.namespace
#     }
#   )
# }
#
# resource "kubectl_manifest" "traefik_dashboard_ing" {
#   yaml_body = templatefile(
#     local.traefik_dashboard_ing_value_file,
#     {
#       traefik_host       = "traefik.local.nthedao.info"
#       ingress_route_name = var.traefik_dashboard_ingress_route_name
#       namespace          = var.namespace
#     }
#   )
# }

# resource "kubectl_manifest" "traefik_dashboard_ingroute" {
#   yaml_body = templatefile(
#     local.traefik_dashboard_ingroute_value_file,
#     {
#       ingress_route_name = var.traefik_dashboard_ingroute_name
#       namespace          = var.traefik_conf.namespace
#     }
#   )
# }

resource "kubectl_manifest" "gateway_class" {
  yaml_body = templatefile(local.traefik_gc_file, {
    gateway_class_name = local.traefik_gc_name
  })
}

resource "kubectl_manifest" "gateway_class" {
  yaml_body = templatefile(local.traefik_gw_file, {
    namespace          = var.traefik_conf.namespace
    gateway_class_name = local.traefik_gc_name
    name               = local.traefik_gw_name
  })
}

resource "kubectl_manifest" "traefik_dashboard_gateway_api" {
  yaml_body = templatefile(
    local.traefik_dashboard_gateway_api_file,
    {
      name               = "traefik-dashboard"
      gateway_class_name = local.traefik_gc_name
      namespace          = var.traefik_conf.namespace
    }
  )

  depends_on = [kubectl_manifest.gateway_class]
}

locals {
  gc_file = "${path.module}/templates/traefik/gc/traefik_gc.yml.tftpl"
  gc_name = "traefik"
  gw_file = "${path.module}/templates/traefik/gateway-api/gateway.yml.tftpl"
  gw_name = "traefik"

  dashboard_gwa_file = "${path.module}/templates/traefik/gateway-api/dashboard_gwa.yml.tftpl"

  dashboard_svc_file      = "${path.module}/templates/traefik/svcs/dashboard_svc.yml.tftpl"
  dashboard_ing_file      = "${path.module}/templates/traefik/ings/dashboard_ing.yml.tftpl"
  dashboard_ingroute_file = "${path.module}/templates/traefik/ings/dashboard_ingroute.yml.tftpl"
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

resource "kubectl_manifest" "dashboard_ingroute" {
  yaml_body = templatefile(
    local.dashboard_ingroute_file,
    {
      ingress_route_name = var.dashboard_ingroute_name
      namespace          = var.traefik_conf.namespace
    }
  )
}

# resource "kubectl_manifest" "gateway_class" {
#   yaml_body = templatefile(local.gc_file, {
#     gateway_class_name = local.gc_name
#   })
# }
#
# resource "kubectl_manifest" "gateway" {
#   yaml_body = templatefile(local.gw_file, {
#     namespace          = var.traefik_conf.namespace
#     gateway_class_name = local.gc_name
#     name               = local.gw_name
#   })
#
#   depends_on = [kubectl_manifest.gateway_class]
# }
#
# resource "kubectl_manifest" "traefik_dashboard_gateway_api" {
#   yaml_body = templatefile(
#     local.dashboard_gwa_file,
#     {
#       name               = "traefik-dashboard"
#       gateway_class_name = local.gc_name
#       namespace          = var.traefik_conf.namespace
#     }
#   )
#
#   depends_on = [kubectl_manifest.gateway]
# }

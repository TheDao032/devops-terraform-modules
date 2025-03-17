locals {
  traefik_gateway_class_file            = "${path.module}/traefik/gc/traefik_gc.yml.tftpl"
  traefik_dashboard_ingroute_value_file = "${path.module}/traefik/ings/dashboard_ingroute.yml.tftpl"
  traefik_gc_name                       = "traefik"

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

resource "kubectl_manifest" "traefik_dashboard_ingroute" {
  yaml_body = templatefile(
    local.traefik_dashboard_ingroute_value_file,
    {
      ingress_route_name = var.traefik_dashboard_ingroute_name
      namespace          = var.namespace
    }
  )
}

resource "kubectl_manifest" "gateway_class" {
  yaml_body = templatefile(local.traefik_gateway_class_file, {
    gateway_class_name = local.traefik_gc_name
  })
}

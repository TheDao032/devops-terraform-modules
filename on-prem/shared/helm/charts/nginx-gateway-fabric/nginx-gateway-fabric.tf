# locals {
#   value_file = "${path.module}/templates/nginx-gateway-fabric/values/values.yml.tftpl"
# }
#
# resource "helm_release" "nginx-gateway-fabric" {
#   name             = var.helm_release_name
#   namespace        = var.namespace
#   repository       = var.helm_repository
#   version          = var.chart_version
#   chart            = var.helm_release_chart
#   create_namespace = true
#   upgrade_install  = true
#   values = (fileexists(local.value_file) ?
#     [
#       templatefile(
#         local.value_file,
#         {
#           gateway_fabric = var.nginx_gateway_fabric
#         }
#       )
#   ] : null)
# }

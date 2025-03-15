# locals {
#   traefik_gateway_class_file = "${path.module}/traefik/gateway-classes/traefik_class.yml.tftpl"
#   traefik_gateway_class_name = "traefik"
# }
#
# resource "kubectl_manifest" "storage_class" {
#   yaml_body = templatefile(local.traefik_gateway_class_file, {
#     gateway_class_name = local.traefik_gateway_class_name
#   })
# }

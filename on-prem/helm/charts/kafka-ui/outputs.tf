output "internal_bootstrap_server" {
  value = "${var.helm_release_name}.${var.namespace}.svc.cluster.local"
}

# output "rendered_yaml" {
#   value = templatefile("${path.module}/templates/ings/traefik_ingroute.yml.tftpl", {
#     ingress_route_name           = "kafka-ui"
#     namespace                    = "default"
#     match_condition              = local.ingressroute_list.kafka_ui.match_condition
#     services                     = local.ingressroute_list.kafka_ui.services
#     middleware_strip_prefix_list = local.ingressroute_list.kafka_ui.middleware_strip_prefix_list
#   })
# }

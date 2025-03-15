output "traefik_gateway_class_name" {
  value = local.traefik_gateway_class_name
}

output "gateway_api_crds_raw" {
  value = data.http.gateway_api_crds_raw
}

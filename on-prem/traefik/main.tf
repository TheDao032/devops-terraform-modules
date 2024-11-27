resource "kubectl_manifest" "traefik_dashboard_ingroute" {
  yaml_body = templatefile(
    local.cloudflare_secret_value_file,
    {
      traefik_host       = "traefik.local.nthedao.info"
      ingress_route_name = var.traefik_dashboard_ingress_route_name
      namespace          = var.namespace
    }
  )
}

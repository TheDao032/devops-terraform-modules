output "ingress_hosts" {
  description = "Hosts that got a Traefik Ingress."
  value       = keys(var.routes)
}

output "traefik_dashboard_host" {
  description = "Host the Traefik dashboard IngressRoute serves (null if not enabled)."
  value       = try(var.traefik_dashboard.host, null)
}

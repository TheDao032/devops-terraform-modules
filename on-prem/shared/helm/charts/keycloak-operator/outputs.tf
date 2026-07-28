# The operator creates a Service named "<keycloak-cr-name>-service" exposing HTTP on 8080 and
# HTTPS on 8443. The Gateway API HTTPRoute backend should target this (:8080, since httpEnabled).
output "service_name" {
  description = "Keycloak Service the HTTPRoute backend should target."
  value       = "keycloak-service"
}

output "service_http_port" {
  description = "HTTP port on the Keycloak Service (httpEnabled)."
  value       = 8080
}

output "namespace" {
  value = var.namespace
}

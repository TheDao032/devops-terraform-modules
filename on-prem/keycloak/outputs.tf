output "kafka_ui_credentials" {
  description = "Object containing client details"
  value = {
    keycloak_host = "${var.keycloak_host}${var.keycloak_conf.ingress.prefix}"
    client_id     = var.clients.kafka_ui.id
    client_secret = var.clients.kafka_ui.secret
    client_name   = var.clients.kafka_ui.name
    client_prefix = var.clients.kafka_ui.prefix
  }
  sensitive = true
}

module "output" {
  source           = "../secrets-stored"
  environment      = var.environment
  vault_mount_path = var.vault_mount_path
  parameters = {
    "keycloak/params" = {
      host = "${var.keycloak_host}${var.keycloak_conf.ingress.prefix}"
    }

    "keycloak/kafka-ui/creds" = {
      client_id     = var.clients.kafka_ui.id
      client_secret = var.clients.kafka_ui.secret
      client_name   = var.clients.kafka_ui.name
      client_prefix = var.clients.kafka_ui.prefix
    }
  }

  tags = var.tags
}

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

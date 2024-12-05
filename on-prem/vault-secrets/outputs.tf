output "jenkins_secrets" {
  value     = local.jenkins_secrets
  sensitive = true
}

output "grafana_secrets" {
  value     = local.grafana_secrets
  sensitive = true
}

output "kafka_secrets" {
  value     = local.kafka_secrets
  sensitive = true
}

output "database_secrets" {
  value     = local.database_secrets
  sensitive = true
}

output "keycloak_secrets" {
  value     = local.keycloak_secrets
  sensitive = true
}

# output "database_paramaters" {
#   value = local.database_secrets_parameters
# }

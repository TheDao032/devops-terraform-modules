output "jenkins_secrets" {
  value     = local.jenkins_secrets
  sensitive = true
}

output "grafana_secrets" {
  value     = local.grafana_secrets
  sensitive = true
}

output "kafka_secrets" {
  value     = local.grafana_secrets
  sensitive = true
}

output "database_secrets" {
  value     = local.database_secrets
  sensitive = true
}

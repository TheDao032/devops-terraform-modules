locals {
  secrets_parameters         = { for k, v in var.secrets : k => v if contains(split(" ", v), "_RANDOM_") }
  secrets_resolve_parameters = { for k, v in random_password.secrets : k => v.result }
  secrets                    = merge(var.secrets, local.secrets_resolve_parameters)
}

resource "random_password" "secrets" {
  for_each         = local.secrets_parameters
  length           = regex("[0-9]+", each.value)
  override_special = "!()-_=+"
  lifecycle {
    ignore_changes = [
      override_special
    ]
  }
}

resource "vault_mount" "kv" {
  path        = var.environment
  type        = "kv"
  options     = {
    version = "2"
  }
  description = "KV Version 2 secret engine mount"
}

resource "vault_generic_secret" "jenkins_secrets" {
  path = "${vault_mount.kv.path}/${var.jenkins_crds_path}"

  data_json = jsonencode(
    {
      "username" = "${local.secrets.jenkinsUsername}",
      "password" = "${local.secrets.jenkinsPassword}",
    }
  )
}

resource "vault_generic_secret" "grafana_secrets" {
  path = "${vault_mount.kv.path}/${var.grafana_crds_path}"

  data_json = jsonencode(
    {
      "username" = "${local.secrets.grafanaUsername}",
      "password" = "${local.secrets.grafanaPassword}",
    }
  )
}

resource "vault_generic_secret" "kafka_secrets" {
  path = "${vault_mount.kv.path}/${var.kafka_crds_path}"

  data_json = jsonencode(
    {
      "username" = "${local.secrets.kafkaClientUsername}",
      "password" = "${local.secrets.kafkaClientPassword}",
    }
  )
}

resource "vault_generic_secret" "k3s_params" {
  path = "${vault_mount.kv.path}/${var.k3s_params_path}"

  data_json = jsonencode(
    var.k3s_params
  )
}

# resource "vault_generic_secret" "psql_server_secrets" {
#   path = "${vault_mount.kv.path}/psql_server"
#
#   data_json = jsonencode(
#     {
#       "conn-pool"    = "${var.psql_vms.conn-pool}",
#       "coordinator1" = "${var.psql_vms.coordinator1}",
#       "worker1"      = "${var.psql_vms.worker1}",
#       "worker2"      = "${var.psql_vms.worker2}",
#     }
#   )
# }

resource "vault_generic_secret" "vault_secrets" {
  path = "${vault_mount.kv.path}/vault"

  data_json = jsonencode(
    var.vault_secrets
  )
}

resource "vault_generic_secret" "vault_params" {
  path = "${vault_mount.kv.path}/vault"

  data_json = jsonencode(
    var.vault_params
  )
}


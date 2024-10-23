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
  path        = "${var.kv_secret_path}_${var.environment}"
  type        = "kv"
  options     = {
    version = "2"
  }
  description = "KV Version 2 secret engine mount"
}

resource "vault_generic_secret" "jenkins_secrets" {
  path = "${vault_mount.kv.path}/jenkins"

  data_json = jsonencode(
    {
      "jenkins_username" = "${local.secrets.jenkinsUsername}",
      "jenkins_password" = "${local.secrets.jenkinsPassword}",
    }
  )
}

resource "vault_generic_secret" "grafana_secrets" {
  path = "${vault_mount.kv.path}/grafana"

  data_json = jsonencode(
    {
      "grafana_username" = "${local.secrets.grafanaUsername}",
      "grafana_password" = "${local.secrets.grafanaPassword}",
    }
  )
}


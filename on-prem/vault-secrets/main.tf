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
  path        = "${var.kv_secret_path}_${var.environment}_terraform"
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

resource "vault_generic_secret" "k3s_vms" {
  path = "${vault_mount.kv.path}/k3s/vms"

  data_json = jsonencode(
    var.k3s_vms
    # {
    #   "server-1" = "${var.k3s_vms.server_1}",
    #   "server-2" = "${var.k3s_vms.server_2}",
    #   "agent-1"  = "${var.k3s_vms.agent_1}",
    #   "agent-2"  = "${var.k3s_vms.agent_2}",
    # }
  )
}

resource "vault_generic_secret" "k3s_envs" {
  path = "${vault_mount.kv.path}/k3s/envs"

  data_json = jsonencode(
    var.k3s_envs
    # {
    #   "keepalived_virtual_ip" = var.k3s_envs.keepalived_virtual_ip,
    #   "load_balancer_port": var.k3s_envs.load_balancer_port,
    #   "psql_version": var.k3s_envs.psql_version,
    #   "k3s_server_cidr_range": var.k3s_envs.k3s_server_cidr_range,
    #   "k3s_version": var.k3s_envs.k3s_version,
    #   "api_endpoint": var.k3s_envs.api_endpoint,
    #   "extra_server_args": "",
    #   "extra_agent_args": "",
    # }
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

# resource "vault_generic_secret" "vault_secrets" {
#   path = "${vault_mount.kv.path}/vault"
#
#   data_json = jsonencode(
#     {
#       "server" = "${var.vault_vms.server}",
#     }
#   )
# }
#

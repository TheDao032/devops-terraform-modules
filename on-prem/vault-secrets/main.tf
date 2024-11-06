resource "vault_mount" "kv" {
  path        = var.environment
  type        = "kv"
  options     = {
    version = "2"
  }
  description = "KV Version 2 secret engine mount"
}

resource "vault_generic_secret" "k3s" {
  for_each = var.k3s
  path = "${vault_mount.kv.path}/${each.key}"

  data_json = jsonencode(
    each.value
  )
}

resource "vault_generic_secret" "vault_secrets" {
  for_each = var.vault
  path = "${vault_mount.kv.path}/${each.key}"

  data_json = jsonencode(
    each.value
  )

  depends_on = [ vault_mount.kv ]
}

resource "vault_generic_secret" "global_secrets" {
  for_each = var.global
  path = "${vault_mount.kv.path}/${each.key}"

  data_json = jsonencode(
    each.value
  )

  depends_on = [ vault_mount.kv ]
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


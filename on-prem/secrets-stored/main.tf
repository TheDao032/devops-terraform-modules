resource "vault_kv_secret_v2" "main" {
  for_each     = var.parameters
  name         = each.key
  mount        = var.vault_mount_path
  disable_read = true

  data_json = jsonencode(
    each.value
  )
}

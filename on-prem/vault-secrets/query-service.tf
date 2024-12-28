resource "vault_generic_secret" "query_service_secrets" {
  for_each = var.query_service
  path     = "${vault_mount.kv.path}/${each.key}"

  data_json = jsonencode(
    each.value
  )

  depends_on = [vault_mount.kv]
}

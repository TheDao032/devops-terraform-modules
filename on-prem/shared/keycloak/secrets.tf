# Push each configured client's GENERATED secret into Vault (TF → Vault → ESO → app), so the
# confidential client_secret never needs a manual hand-off. Uses the env-configured vault provider
# (VAULT_ADDR / VAULT_TOKEN). No-op when vault_push.enabled = false.
resource "vault_kv_secret_v2" "client_secret" {
  for_each = var.vault_push.enabled ? var.vault_push.clients : {}

  mount        = var.vault_push.mount
  name         = each.value.path
  disable_read = true # write-only: don't read the secret back (avoids needing read policy)

  data_json = jsonencode({
    (each.value.key) = keycloak_openid_client.main[each.key].client_secret
  })
}

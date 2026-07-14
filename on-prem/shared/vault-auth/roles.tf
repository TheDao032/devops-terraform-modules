# ── Auth method: AppRole (machine / service) ─────────────────────────────────
# Byte-IDENTICAL to the vault-roles module (same resource addresses) so a vault-roles caller
# migrates to vault-auth by changing ONLY its `source` — no `state mv`, no destroy/recreate of
# the auth backend. The backend is created unconditionally (as in vault-roles); the roles /
# secret_ids / logins are per-entry, so a userpass-only stack (roles = {}) just leaves an empty
# approle backend enabled. role_id + secret_id + login token are exposed via outputs.tf.

resource "vault_auth_backend" "main" {
  type = "approle"
}

resource "vault_approle_auth_backend_role" "main" {
  for_each       = var.roles
  backend        = vault_auth_backend.main.path
  role_name      = each.key
  token_policies = [each.key]

  depends_on = [vault_auth_backend.main, vault_policy.main]
}

resource "vault_approle_auth_backend_role_secret_id" "main" {
  for_each  = var.roles
  backend   = vault_auth_backend.main.path
  role_name = vault_approle_auth_backend_role.main[each.key].role_name
}

resource "vault_approle_auth_backend_login" "main" {
  for_each  = var.roles
  backend   = vault_auth_backend.main.path
  role_id   = vault_approle_auth_backend_role.main[each.key].role_id
  secret_id = vault_approle_auth_backend_role_secret_id.main[each.key].secret_id
}

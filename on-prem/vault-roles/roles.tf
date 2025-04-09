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

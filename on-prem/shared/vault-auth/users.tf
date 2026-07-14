# ── Auth method: Userpass (human logins) ─────────────────────────────────────
# Created only when var.users is non-empty. Each user attaches policies defined in roles.tf
# (via policies.tf). Password handling: a value of "{ _RANDOM_ = N }" is replaced by a
# generated N-char password; any other value is written to Vault verbatim. Generated
# passwords are exposed (sensitive) via outputs.tf so a human can actually log in.
locals {
  # Users whose password is a "_RANDOM_" placeholder → generate one for them.
  # split(" ", ...) needs _RANDOM_ as a standalone, space-delimited token, e.g. "{ _RANDOM_ = 18 }".
  random_pw_users = {
    for name, u in var.users : name => u
    if contains(split(" ", u.password), "_RANDOM_")
  }

  # Effective password per user: generated when the value was a placeholder, else the literal.
  user_passwords = {
    for name, u in var.users : name => (
      contains(keys(local.random_pw_users), name)
      ? random_password.users[name].result
      : u.password
    )
  }
}

resource "random_password" "users" {
  for_each = local.random_pw_users

  length           = regex("[0-9]+", each.value.password) # "{ _RANDOM_ = 18 }" → 18
  override_special = "!()-_=+"

  lifecycle {
    ignore_changes = [override_special]
  }
}

resource "vault_auth_backend" "userpass" {
  count = length(var.users) > 0 ? 1 : 0
  type  = "userpass"
}

resource "vault_generic_endpoint" "users" {
  for_each             = var.users
  path                 = "auth/userpass/users/${each.key}"
  ignore_absent_fields = true

  data_json = jsonencode({
    password       = local.user_passwords[each.key]
    token_policies = each.value.policies
  })

  depends_on = [vault_auth_backend.userpass, vault_policy.main]
}

# Escrow GENERATED userpass passwords into KV so they're retrievable without Terraform state
# access (userpass itself stores only a one-way bcrypt hash). Only generated users are written —
# literal-password users are already known to the caller. Requires mount_kv = true (this module
# owns the KV mount). Path: <env>/userpass/<name>. LOCK DOWN this path with a tight policy, and
# treat the value as an INITIAL password — it goes stale if the user rotates their password.
resource "vault_kv_secret_v2" "user_credentials" {
  for_each = var.mount_kv ? local.random_pw_users : {}
  mount    = vault_mount.kv[0].path
  name     = "userpass/${each.key}"

  data_json = jsonencode({
    username = each.key
    password = random_password.users[each.key].result
  })

  depends_on = [vault_generic_endpoint.users]
}

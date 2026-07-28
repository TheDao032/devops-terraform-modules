# AppRole credentials per role — byte-compatible with the vault-roles module's `roles` output,
# so vault-secrets (which consumes role_id/secret_id/client_token) works unchanged after a
# vault-roles → vault-auths migration.
output "roles" {
  description = "Per-role AppRole credentials (role_id, secret_id, client_token)."
  value = {
    for k, v in var.roles : k => {
      role_id      = vault_approle_auth_backend_role.main[k].role_id
      secret_id    = vault_approle_auth_backend_role_secret_id.main[k].secret_id
      client_token = vault_approle_auth_backend_login.main[k].client_token
    }
  }
  sensitive = true
}

output "users" {
  description = "Userpass usernames created."
  value       = keys(var.users)
}

# Generated passwords ONLY (users whose input was a "_RANDOM_" placeholder). Literal-password
# users are omitted — the caller already knows those. Retrieve with:
#   terraform output -json user_generated_passwords   (or via terragrunt)
output "user_generated_passwords" {
  description = "Randomly generated userpass passwords, keyed by username (generated users only)."
  value       = { for name in keys(local.random_pw_users) : name => random_password.users[name].result }
  sensitive   = true
}

output "kv_mount_path" {
  description = "KV-v2 mount path = the org ('fitmate'), empty when mount_kv = false. vault-secrets mounts here."
  value       = var.mount_kv ? vault_mount.kv[0].path : ""
}

output "secret_path_prefix" {
  description = "Folder inside the KV mount that everything lives under, WITH trailing slash ('<env>/', e.g. 'local/'; empty with no org). vault-secrets prepends this to each key so secrets land at <org>/data/<env>/<key>."
  value       = local.key_prefix
}

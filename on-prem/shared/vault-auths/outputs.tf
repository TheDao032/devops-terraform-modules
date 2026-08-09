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
  description = "KV-v2 mount path = the org ('fitmate'). ALWAYS local.kv_mount — the mount lives at this path whether or not THIS unit created it (mount_kv=false units still point vault-secrets at the shared mount). Was `mount_kv ? … : \"\"`, which made per-env vault-secrets write to a mountless `data/<env>/…` → 404."
  value       = local.kv_mount
}

output "secret_path_prefix" {
  description = "Folder inside the KV mount that everything lives under, WITH trailing slash ('<env>/', e.g. 'local/'; empty with no org). vault-secrets prepends this to each key so secrets land at <org>/data/<env>/<key>."
  value       = local.key_prefix
}

# ── Kubernetes auth (per-app ESO SecretStores) ───────────────────────────────
output "k8s_auth_mount" {
  description = "Kubernetes auth backend mount path (e.g. 'kubernetes'); empty when var.k8s_auth is unset. App SecretStores set auth.kubernetes.mountPath to this."
  value       = length(var.k8s_auth) > 0 ? vault_auth_backend.kubernetes[0].path : ""
}

output "k8s_auth_roles" {
  description = "Per-app Kubernetes auth role names (the value each SecretStore sets as auth.kubernetes.role). Keyed by app name."
  value       = { for name in keys(var.k8s_auth) : name => vault_kubernetes_auth_backend_role.this[name].role_name }
}

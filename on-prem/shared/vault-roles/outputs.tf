output "roles" {
  value = {
    for k, v in var.roles : k => {
      role_id      = vault_approle_auth_backend_role.main[k].role_id
      secret_id    = vault_approle_auth_backend_role_secret_id.main[k].secret_id
      client_token = vault_approle_auth_backend_login.main[k].client_token
    }
  }
  sensitive = true
}

# output "rendered_policy" {
#   value = templatefile(local.policies_tmp_file, {
#     environment = var.environment
#     policies    = var.roles["dev"]
#   })
# }

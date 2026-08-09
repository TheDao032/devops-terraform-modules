# Seed users (e.g. the trainee1 e2e test user). Passwords come from var.user_passwords (Vault);
# a user with no password entry is created without one (set it later / via account console).
resource "keycloak_user" "main" {
  for_each = local.users

  realm_id = keycloak_realm.main.id
  username = each.value.username
  enabled  = each.value.enabled
  email    = try(each.value.email, null)
  # Profile fields — set for non-interactive (password-grant) users to satisfy the KC 26 declarative
  # user profile (else VERIFY_PROFILE blocks direct grant). Null when unset → provider leaves blank.
  first_name     = try(each.value.first_name, null)
  last_name      = try(each.value.last_name, null)
  email_verified = try(each.value.email_verified, false)

  # Only set an initial password when one was supplied (empty initial_password is rejected).
  dynamic "initial_password" {
    for_each = lookup(var.user_passwords, each.value.username, "") != "" ? [1] : []
    content {
      value     = var.user_passwords[each.value.username]
      temporary = false
    }
  }
}

# Realm-role assignments for seed users (role NAMES → resolved to IDs).
resource "keycloak_user_roles" "main" {
  for_each = local.users_with_roles

  realm_id = keycloak_realm.main.id
  user_id  = keycloak_user.main[each.key].id
  role_ids = [for r in each.value.realm_roles : keycloak_role.main[r].id]
}

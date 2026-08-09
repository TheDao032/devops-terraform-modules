# Realm roles (e.g. trainee/trainer/admin/super_admin). Services gate on realm_access.roles.
resource "keycloak_role" "main" {
  for_each = local.roles

  realm_id = keycloak_realm.main.id
  name     = each.value
}

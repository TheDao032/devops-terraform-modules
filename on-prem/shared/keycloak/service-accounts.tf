# Service-account role grants — the permission model for Keycloak's ADMIN REST API.
#
# WHY THIS EXISTS
# A backend that must CREATE users (signup, admin-creates-admin) cannot do it with an end-user
# token — it calls the Admin REST API as ITSELF, via a confidential client's service account
# (`service_accounts_enabled = true`, client_credentials grant). Authentication alone is not
# enough: the Admin API authorises every operation against roles owned by the realm's BUILT-IN
# `realm-management` client (manage-users, view-users, …). A service account holding none of them
# authenticates successfully and is then refused every call with 403 — a failure that looks like
# bad credentials but is not.
#
# Without this file the module could enable a service account but never grant it anything, so
# every Admin-API call in the platform would 403. See B-047 / the admin-service Keycloak cutover.
#
# `realm-management` is created by Keycloak itself per realm, so it is a DATA SOURCE, never a
# managed resource. We need its internal UUID (`.id`), not its `client_id` string, because
# keycloak_openid_client_service_account_role.client_id identifies the client that OWNS the role.
#
# Verified against provider keycloak/keycloak v5.9.0 (terraform providers schema -json):
#   keycloak_openid_client_service_account_role → realm_id, client_id, role, service_account_user_id (all required)
#   keycloak_openid_client.service_account_user_id → computed attribute, safe to reference
data "keycloak_openid_client" "realm_management" {
  # Only look it up when something actually needs a grant — avoids an API call on every plan for
  # realms that have no service accounts at all.
  count = length(local.service_account_roles) > 0 ? 1 : 0

  realm_id  = keycloak_realm.main.id
  client_id = "realm-management"
}

# One grant per (client, role). The key "<client_id>:<role>" keeps for_each stable across plans —
# same pattern as local.client_audiences.
resource "keycloak_openid_client_service_account_role" "main" {
  for_each = local.service_account_roles

  realm_id = keycloak_realm.main.id

  # The service account USER of the client being granted the permission. Computed by Keycloak when
  # service_accounts_enabled = true; null otherwise, which is why the validation in variables.tf
  # rejects service_account_roles without service_accounts_enabled.
  service_account_user_id = keycloak_openid_client.main[each.value.client_id].service_account_user_id

  # The client that OWNS the role — realm-management's internal UUID, NOT the literal string.
  client_id = data.keycloak_openid_client.realm_management[0].id

  role = each.value.role
}

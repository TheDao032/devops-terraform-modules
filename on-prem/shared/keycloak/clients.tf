# OIDC clients (e.g. the fitmate-website confidential BFF). CONFIDENTIAL clients get a generated
# client_secret (exported below / pushed to Vault by secrets.tf).
resource "keycloak_openid_client" "main" {
  for_each = local.clients

  realm_id  = keycloak_realm.main.id
  client_id = each.value.client_id
  name      = try(each.value.name, each.value.client_id)
  enabled   = true

  access_type                  = each.value.access_type
  standard_flow_enabled        = each.value.standard_flow_enabled
  direct_access_grants_enabled = each.value.direct_access_grants_enabled
  implicit_flow_enabled        = each.value.implicit_flow_enabled
  service_accounts_enabled     = each.value.service_accounts_enabled

  valid_redirect_uris             = each.value.valid_redirect_uris
  valid_post_logout_redirect_uris = each.value.valid_post_logout_redirect_uris
  web_origins                     = each.value.web_origins

  # PKCE (S256) for public/BFF auth-code flows. Null → Keycloak default (unset).
  pkce_code_challenge_method = each.value.pkce_code_challenge_method
}

# Audience mapper — injects a custom audience (e.g. "fitmate-backend") into the client's ACCESS
# token. CRITICAL: backend services reject tokens whose `aud` doesn't contain their name, and
# Keycloak's default aud is `account`.
resource "keycloak_openid_audience_protocol_mapper" "aud" {
  for_each = local.client_audiences

  realm_id                 = keycloak_realm.main.id
  client_id                = keycloak_openid_client.main[each.value.client_id].id
  name                     = "aud-${each.value.audience}"
  included_custom_audience = each.value.audience
  add_to_access_token      = true
  add_to_id_token          = false
}

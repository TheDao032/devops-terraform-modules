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
# User-attribute mapper (B-M01) — copies a Keycloak USER ATTRIBUTE into the ACCESS token as a
# claim, so a service can identify the caller from the signed token rather than from a request
# field the caller controls.
#
# add_to_access_token = true / add_to_id_token = false mirrors the audience mapper below:
# backend services read the ACCESS token; the ID token is for the browser session and has no
# need to carry an internal database identifier.
#
# ⚠️ The claim is only as trustworthy as the attribute behind it. The attribute MUST be written
# by a service using its own admin credentials, never by the end user.
resource "keycloak_openid_user_attribute_protocol_mapper" "user_attribute_claim" {
  for_each = local.client_attribute_claims

  realm_id            = keycloak_realm.main.id
  client_id           = keycloak_openid_client.main[each.value.client_id].id
  name                = "attr-${each.value.claim_name}"
  user_attribute      = each.value.user_attribute
  claim_name          = each.value.claim_name
  claim_value_type    = each.value.claim_type
  add_to_access_token = true
  add_to_id_token     = false
  add_to_userinfo     = false
}

resource "keycloak_openid_audience_protocol_mapper" "aud" {
  for_each = local.client_audiences

  realm_id                 = keycloak_realm.main.id
  client_id                = keycloak_openid_client.main[each.value.client_id].id
  name                     = "aud-${each.value.audience}"
  included_custom_audience = each.value.audience
  add_to_access_token      = true
  add_to_id_token          = false
}

# Social-login IDENTITY PROVIDERS (IN-14).
#
# Keycloak brokers the OAuth flow with the provider and issues a NORMAL Keycloak JWT, so no service
# changes when social login is enabled:
#
#     browser -> Keycloak -> Google -> Keycloak -> app receives a Keycloak JWT
#
# ⚠️ The provider client_secret is used BY KEYCLOAK for the code exchange and must never be
# delivered to an application. The earlier attempt (closed PR #14) shipped it to trainer-service as
# SUPERTOKENS_THIRDPARTY_GOOGLE_CLIENTSECRET — a live credential handed to a process with no code
# path that reads it, under a naming scheme banned in fitmate-gitops
# apps/trainee-service/prod/values.yaml:63 ("SuperTokens is RETIRED (Keycloak-only)").
#
# ⚠️ REDIRECT URI — the step that is always forgotten. Register Keycloak's broker endpoint at the
# PROVIDER console or login fails immediately after consent:
#     <issuer>/realms/<realm>/broker/google/endpoint
#     <issuer>/realms/<realm>/broker/facebook/endpoint
# e.g. http://keycloak.k3s.fitmate/realms/fitmate-dev/broker/google/endpoint
# Terraform cannot do this; it is console work at Google / Meta.
#
# Google and Facebook get first-class resources in keycloak/keycloak (verified against the pinned
# provider's schema, v5.9.0 — both exist, and every argument used below is valid on both). Adding a
# third provider means adding a resource here AND extending the alias validation in variables.tf.

resource "keycloak_oidc_google_identity_provider" "main" {
  for_each = { for a, i in local.identity_providers : a => i if a == "google" }

  realm         = keycloak_realm.main.id
  client_id     = each.value.client_id
  client_secret = each.value.client_secret
  enabled       = each.value.enabled

  display_name   = each.value.display_name
  gui_order      = each.value.gui_order
  default_scopes = each.value.default_scopes

  # See the security note on these in variables.tf — trust_email in particular decides whether a
  # social login can silently take over an existing account with the same email address.
  trust_email                   = each.value.trust_email
  link_only                     = each.value.link_only
  sync_mode                     = each.value.sync_mode
  hide_on_login_page            = each.value.hide_on_login_page
  first_broker_login_flow_alias = each.value.first_broker_login_flow_alias
}

resource "keycloak_oidc_facebook_identity_provider" "main" {
  for_each = { for a, i in local.identity_providers : a => i if a == "facebook" }

  realm         = keycloak_realm.main.id
  client_id     = each.value.client_id
  client_secret = each.value.client_secret
  enabled       = each.value.enabled

  display_name   = each.value.display_name
  gui_order      = each.value.gui_order
  default_scopes = each.value.default_scopes

  trust_email                   = each.value.trust_email
  link_only                     = each.value.link_only
  sync_mode                     = each.value.sync_mode
  hide_on_login_page            = each.value.hide_on_login_page
  first_broker_login_flow_alias = each.value.first_broker_login_flow_alias
}

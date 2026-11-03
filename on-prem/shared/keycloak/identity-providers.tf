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

# ── Sign in with Apple ────────────────────────────────────────────────────────────────────────
#
# Apple is the ONLY provider here using the GENERIC resource with an explicit provider_id,
# because Keycloak ships no typed Apple resource and no built-in Apple provider at all. The
# `apple` provider_id is registered by the community extension baked into our custom Keycloak
# image (fitmate-website keycloak-theme/Dockerfile, pinned 1.17.0). Proven present in CI's own
# build log, not inferred:
#     KC-SERVICES0047: apple-username-template-mapper (at.klausbetz.provider...)
#     KC-SERVICES0047: apple-user-attribute-mapper    (at.klausbetz.provider...)
#
# 🔴 THIS RESOURCE WILL FAIL TO APPLY IF THE CLUSTER'S KEYCLOAK IMAGE LACKS THAT EXTENSION.
# provider_id "apple" is not a Keycloak built-in; against stock Keycloak it does not exist.
# Deploy the image FIRST, then apply this. Ordering is not optional and Terraform cannot see
# the dependency — the image tag lives in a different stack (shared/ops-tools).
#
# WHY THE GENERIC RESOURCE AND NOT A NEW TYPED ONE: the typed google/facebook resources exist
# in the Keycloak terraform provider upstream. There is no keycloak_oidc_apple_identity_provider
# because Apple is not an upstream Keycloak provider. Writing our own wrapper would add a layer
# that only renames fields.
resource "keycloak_oidc_identity_provider" "apple" {
  for_each = { for a, i in local.identity_providers : a => i if a == "apple" }

  realm       = keycloak_realm.main.id
  alias       = "apple"
  provider_id = "apple"

  client_id = each.value.client_id
  # 🔴 NOT a password: this is the RAW .p8 private key. The extension mints a fresh ES256 JWT
  # per login from it. See the team_id/key_id note in variables.tf for why hand-minting the JWT
  # was a failure mode we could not monitor.
  client_secret = each.value.client_secret

  # Required by the provider's schema even though the extension resolves Apple's endpoints
  # itself. These are Apple's documented, stable endpoints.
  authorization_url = "https://appleid.apple.com/auth/authorize"
  token_url         = "https://appleid.apple.com/auth/token"

  enabled      = each.value.enabled
  display_name = each.value.display_name
  gui_order    = each.value.gui_order

  # Apple returns "name email" — NOT the OIDC-standard "openid profile email". Apple has no
  # userinfo endpoint; claims arrive inside the id_token, and `name` is sent ONLY on the very
  # first authorization for a given user and never again.
  default_scopes = coalesce(each.value.default_scopes, "name email")

  # 🔴 trust_email MUST stay false for Apple, and the reason differs from Facebook's.
  #
  # Apple lets a user hide their real address behind a per-app relay
  # (xxxxx@privaterelay.appleid.com). That address is real and deliverable but is NOT proof of
  # control over any personal mailbox, and a user may also supply an arbitrary address Apple
  # never verified. Trusting it would auto-link an Apple login to an existing FITMate account
  # by email — the account-takeover path ADR-118 Option A was written to prevent for Facebook.
  # The upstream extension's own README recommends the same setting.
  trust_email = each.value.trust_email

  link_only                     = each.value.link_only
  sync_mode                     = each.value.sync_mode
  hide_on_login_page            = each.value.hide_on_login_page
  first_broker_login_flow_alias = each.value.first_broker_login_flow_alias

  # teamId/keyId are read by the extension's own factory, so they travel as extra_config rather
  # than first-class fields. Validated as present in variables.tf — missing values are accepted
  # by Keycloak and fail only at login, with Apple's indistinguishable invalid_grant.
  extra_config = {
    teamId = each.value.team_id
    keyId  = each.value.key_id
  }
}

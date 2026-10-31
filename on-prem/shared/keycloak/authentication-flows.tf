# ── Social-only browser flow (ADR-118 step 3 part 2) ────────────────────────────────────────────
#
# Removes the username/password form from the PUBLIC login page without touching anyone else's.
#
# ─── WHAT THE BUILT-IN `browser` FLOW CONTAINS ────────────────────────────────────────────────
#
# Measured on fitmate-dev 2026-10-31 via
#   kcadm get authentication/flows/browser/executions -r fitmate-dev
#
#   Cookie                          ALTERNATIVE  auth-cookie
#   Kerberos                        DISABLED     auth-spnego
#   Identity Provider Redirector    ALTERNATIVE  identity-provider-redirector
#   Organization                    ALTERNATIVE  (subflow)
#   forms                           ALTERNATIVE  (subflow)   <-- the password form lives HERE
#     Username Password Form          REQUIRED   auth-username-password-form
#     Browser - Conditional 2FA       CONDITIONAL
#       OTP Form / WebAuthn / Recovery Authentication Code Form
#
# 🔑 The password form is NOT a top-level execution — it sits inside the `forms` SUBFLOW. So a
# social-only flow does not disable executions one at a time; it simply never declares that
# subflow. Dropping `forms` removes the password box AND the 2FA subflow that depends on it,
# and nothing else.
#
# ─── WHY TWO EXECUTIONS IS THE WHOLE FLOW ─────────────────────────────────────────────────────
#
#   auth-cookie                   ALTERNATIVE  honours an existing SSO session, so a user who
#                                              already signed in is not bounced to the IdP again.
#   identity-provider-redirector  ALTERNATIVE  sends everyone else to Google/Facebook.
#
# ⚠️ ORDER IS LOAD-BEARING. `priority` decides evaluation order and Keycloak takes the FIRST
# ALTERNATIVE that succeeds. With the redirector first, an authenticated user is sent back to the
# IdP on every navigation instead of reusing their session.
#
# ─── WHY PER-CLIENT BINDING AND NOT THE REALM DEFAULT ─────────────────────────────────────────
#
# A realm has ONE default browser flow. Pointing the realm at this one would lock out every
# administrator (`fitmate-admin-bff`, standard_flow_enabled = true) and all 18 password-only
# fixtures. `authentication_flow_binding_overrides.browser_id` sets the flow PER CLIENT instead:
# one realm, two doors. That is ADR-118's ONE REALM decision, unchanged.

locals {
  # Clients that opted in. Empty by default — see `social_only_login` in variables.tf for why the
  # default must stay false in a module shared by dev, stg and prod.
  social_only_clients = {
    for c in var.realm.clients : c.client_id => c if try(c.social_only_login, false)
  }

  # The flow is created only when at least one client wants it. A realm that opted nobody in
  # plans to zero change rather than gaining an unused flow.
  social_only_flow_enabled = length(local.social_only_clients) > 0
}

resource "keycloak_authentication_flow" "social_only_browser" {
  count = local.social_only_flow_enabled ? 1 : 0

  realm_id    = keycloak_realm.main.id
  alias       = "fitmate social only browser"
  description = "ADR-118: identity providers only. No username/password form. Bound per client via authenticationFlowBindingOverrides, never as the realm default."
  provider_id = "basic-flow"
}

# Honour an existing SSO session first.
resource "keycloak_authentication_execution" "social_only_cookie" {
  count = local.social_only_flow_enabled ? 1 : 0

  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_flow.social_only_browser[0].alias
  authenticator     = "auth-cookie"
  requirement       = "ALTERNATIVE"
  priority          = 10
}

# Everyone else goes to an identity provider.
resource "keycloak_authentication_execution" "social_only_idp_redirector" {
  count = local.social_only_flow_enabled ? 1 : 0

  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_flow.social_only_browser[0].alias
  authenticator     = "identity-provider-redirector"
  requirement       = "ALTERNATIVE"
  priority          = 20

  # 🔴 Terraform does not infer ordering from `priority`. Without this the two executions can be
  # created in either order, and a flow whose first ALTERNATIVE is the redirector re-authenticates
  # a user who already has a valid session.
  depends_on = [keycloak_authentication_execution.social_only_cookie]
}

# ── The hint-less arrival (B-FLOW-DEADEND, measured 2026-10-31) ─────────────────────────────────
#
# 🔴 WHY THIS BLOCK EXISTS. The flow above shipped without it and BROKE the login page.
#
# `identity-provider-redirector` only redirects when the request carries `kc_idp_hint`, or when
# this config gives it a `defaultProvider`. With neither it falls through — and because the flow
# deliberately omits the built-in `forms` subflow, there is NOTHING LEFT TO RENDER A PAGE.
# Keycloak ends the flow and the user sees a bare "Sign-in failed".
#
# Measured on dev before this block:
#   'Continue with Google'  (kc_idp_hint=google) -> /trainee, real profile id   WORKED
#   'Sign in with FITMate'  (no hint)            -> "Sign-in failed"            BROKE
#
# 🔑 The password form and the thing that DRAWS the login page were the same subflow. Removing
# `forms` to delete the password box also deleted the renderer. That is not a Keycloak quirk —
# it is what a flow with no form-rendering execution means.
#
# With a defaultProvider set, a hint-less arrival (a bookmark, a direct /auth link, an expired
# session resuming) goes straight to that identity provider instead of dead-ending.
resource "keycloak_authentication_execution_config" "social_only_default_idp" {
  count = local.social_only_flow_enabled && var.realm.social_only_default_idp != null ? 1 : 0

  realm_id     = keycloak_realm.main.id
  execution_id = keycloak_authentication_execution.social_only_idp_redirector[0].id
  alias        = "fitmate-social-only-default-idp"

  config = {
    defaultProvider = var.realm.social_only_default_idp
  }
}

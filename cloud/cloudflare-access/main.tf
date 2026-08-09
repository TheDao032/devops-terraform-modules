# ── Cloudflare Access (Zero Trust) — identity gate at the edge for admin hosts ─────────────────
# Puts vault/traefik/argocd/kafka-ui behind a login BEFORE traffic reaches the tunnel, so the admin
# UIs aren't publicly reachable. Default IdP is Cloudflare's one-time PIN (email OTP) — no external
# IdP needed. Provider (cloudflare) configured by the caller (terragrunt). This module declares none.
#
# PREREQUISITE: a Cloudflare Zero Trust organization must exist (dash → Zero Trust → pick a team name →
# <team>.cloudflareaccess.com). Free plan covers up to 50 users. See [[production-cloudflare-tunnel]] Phase 6.

# One reusable "allow only these emails" policy, attached to every admin app below.
resource "cloudflare_zero_trust_access_policy" "allow_owner" {
  account_id = var.account_id
  name       = "fitmate-prod-allow-owner"
  decision   = "allow"

  include = [for e in var.allowed_emails : { email = { email = e } }]
}

# One self-hosted Access application per admin host, gated by the policy above.
resource "cloudflare_zero_trust_access_application" "app" {
  for_each = var.apps

  account_id       = var.account_id
  name             = "${var.app_name_prefix}${each.value.name}"
  domain           = each.key
  type             = "self_hosted"
  session_duration = var.session_duration

  # Attach the shared allow-owner policy (ascending precedence).
  policies = [{
    id         = cloudflare_zero_trust_access_policy.allow_owner.id
    precedence = 1
  }]
}

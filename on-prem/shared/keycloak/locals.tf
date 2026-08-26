locals {
  roles   = toset(var.realm.roles)
  clients = { for c in var.realm.clients : c.client_id => c }
  # Keyed by `key` when set, else `username`. The indirection lets a user's username change (Keycloak
  # rewrites it to the email under registration_email_as_username) WITHOUT moving the Terraform
  # resource address — which would otherwise destroy and recreate the user, issuing a new `sub`.
  users = { for u in var.realm.users : coalesce(u.key, u.username) => u }

  # Flatten each client's custom audiences → one audience protocol-mapper per (client, audience).
  # Key "<client_id>:<audience>" keeps the for_each stable across plans.
  client_audiences = length(var.realm.clients) > 0 ? merge([
    for c in var.realm.clients : {
      for aud in c.audiences : "${c.client_id}:${aud}" => { client_id = c.client_id, audience = aud }
    }
  ]...) : {}

  # Only users that actually have realm roles to assign.
  users_with_roles = { for u in var.realm.users : coalesce(u.key, u.username) => u if length(u.realm_roles) > 0 }

  # Flatten each client's realm-management grants → one grant per (client, role). Key
  # "<client_id>:<role>" keeps the for_each stable across plans (same pattern as client_audiences).
  # Guarded on length so the realm-management DATA SOURCE is skipped entirely when no client needs it.
  service_account_roles = length(var.realm.clients) > 0 ? merge([
    for c in var.realm.clients : {
      for r in c.service_account_roles : "${c.client_id}:${r}" => { client_id = c.client_id, role = r }
    }
  ]...) : {}

  # ── Social-login IdPs (IN-14) ─────────────────────────────────────────────────────────────────
  # An entry with an EMPTY client_secret is deliberately NOT created. The secret comes from
  # `get_env("GOOGLE_CLIENTSECRET", "")`, so an unset variable yields "" — and a Keycloak IdP with a
  # blank secret still renders a login button that fails at the code exchange. Skipping is the safe
  # reading of "not configured"; it also lets `terragrunt plan` work for anyone (or any CI job)
  # without the secrets exported.
  #
  # The skip is NEVER silent: outputs.tf publishes both the configured and skipped aliases, so
  # "why is Google missing from the login page?" is answerable from `terragrunt output` alone.
  identity_providers         = { for i in var.realm.identity_providers : i.alias => i if trimspace(i.client_secret) != "" }
  identity_providers_skipped = [for i in var.realm.identity_providers : i.alias if trimspace(i.client_secret) == ""]
}

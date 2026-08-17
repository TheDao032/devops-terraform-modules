locals {
  roles   = toset(var.realm.roles)
  clients = { for c in var.realm.clients : c.client_id => c }
  users   = { for u in var.realm.users : u.username => u }

  # Flatten each client's custom audiences → one audience protocol-mapper per (client, audience).
  # Key "<client_id>:<audience>" keeps the for_each stable across plans.
  client_audiences = length(var.realm.clients) > 0 ? merge([
    for c in var.realm.clients : {
      for aud in c.audiences : "${c.client_id}:${aud}" => { client_id = c.client_id, audience = aud }
    }
  ]...) : {}

  # Only users that actually have realm roles to assign.
  users_with_roles = { for u in var.realm.users : u.username => u if length(u.realm_roles) > 0 }

  # Flatten each client's realm-management grants → one grant per (client, role). Key
  # "<client_id>:<role>" keeps the for_each stable across plans (same pattern as client_audiences).
  # Guarded on length so the realm-management DATA SOURCE is skipped entirely when no client needs it.
  service_account_roles = length(var.realm.clients) > 0 ? merge([
    for c in var.realm.clients : {
      for r in c.service_account_roles : "${c.client_id}:${r}" => { client_id = c.client_id, role = r }
    }
  ]...) : {}
}

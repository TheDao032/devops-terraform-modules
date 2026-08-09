resource "keycloak_realm" "main" {
  realm        = var.realm.name
  enabled      = var.realm.enabled
  display_name = try(var.realm.display_name, var.realm.name)

  # HTTP lab → "none". The issuer (http://keycloak.k3s.local/realms/<name>) is fixed by the SERVER
  # hostname (Keycloak CR spec.hostname), so no realm-level frontend_url override is needed here.
  ssl_required = var.realm.ssl_required
}

output "realm" {
  description = "The realm name."
  value       = keycloak_realm.main.realm
}

output "issuer" {
  description = "OIDC issuer URL — services set KEYCLOAK_ISSUER / AUTH_KEYCLOAK_ISSUER to this."
  value       = "${var.keycloak_url}/realms/${keycloak_realm.main.realm}"
}

output "client_ids" {
  description = "Map of client_id key -> client_id (handy for downstream references)."
  value       = { for k, c in keycloak_openid_client.main : k => c.client_id }
}

output "client_secrets" {
  description = "Map of client_id -> generated client secret (confidential clients). Sensitive."
  value       = { for k, c in keycloak_openid_client.main : k => c.client_secret }
  sensitive   = true
}

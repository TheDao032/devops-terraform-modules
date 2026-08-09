output "policy_id" {
  description = "ID of the shared allow-owner Access policy."
  value       = cloudflare_zero_trust_access_policy.allow_owner.id
}

output "application_ids" {
  description = "Map of host -> Access application ID."
  value       = { for host, a in cloudflare_zero_trust_access_application.app : host => a.id }
}

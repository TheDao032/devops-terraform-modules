output "tunnel_id" {
  description = "UUID of the cloudflared tunnel."
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

output "tunnel_cname" {
  description = "The CNAME target every proxied hostname points at (<id>.cfargotunnel.com)."
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
}

output "tunnel_token" {
  description = "cloudflared run token (`tunnel run --token`). Store in Vault for the in-cluster deploy (Phase 3)."
  value       = local.tunnel_token
  sensitive   = true
}

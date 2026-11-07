output "record_names" {
  description = "name|type keys actually created — compare against what you intended."
  value       = sort(keys(cloudflare_dns_record.this))
}

# Published so a caller can assert on it. A record that exists is not the same as a record
# that is NOT proxied, and the proxied mistake is invisible from DNS resolution alone.
output "proxied_records" {
  description = "Records created with the Cloudflare proxy ON. For a mail zone this should be empty."
  value       = sort([for k, r in cloudflare_dns_record.this : k if r.proxied])
}

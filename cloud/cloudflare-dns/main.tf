# Ordinary DNS records for a Cloudflare zone.
#
# WHY A SEPARATE MODULE: the only cloudflare_dns_record resources in this repo live in
# cloud/cloudflare-tunnel, which exists to publish tunnel hostnames and derives every record's
# content from the tunnel id. SPF, DKIM and DMARC have nothing to do with a tunnel, and putting
# mail authentication inside a networking module would hide it from anyone looking for it.
#
# Resource is `cloudflare_dns_record` with `content` (provider v5 naming), matching
# cloudflare-tunnel/main.tf:106 — the v4 `cloudflare_record` / `value` spelling does not exist
# in the provider this repo pins.

resource "cloudflare_dns_record" "this" {
  # Keyed by name+type rather than index: an index key makes removing the first record
  # re-create every record after it, which for DKIM means a window where mail fails auth.
  for_each = { for r in var.records : "${r.name}|${r.type}" => r }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  ttl     = each.value.ttl
  proxied = each.value.proxied
  comment = each.value.comment

  priority = each.value.type == "MX" ? each.value.priority : null
}

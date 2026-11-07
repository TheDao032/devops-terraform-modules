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

locals {
  # 🔴 ONE key expression, used by BOTH the for_each below AND the uniqueness validation in
  # variables.tf. They were different once: for_each keyed on name|type while the validation
  # keyed on name|type|content. The validation passed and guarded nothing, and the first real
  # plan died on `Duplicate object key "@|TXT"` — an apex zone legitimately carries several TXT
  # records (here: the Brevo ownership code AND the SPF record).
  #
  # A VALIDATION THAT CHECKS A DIFFERENT UNIQUENESS THAN THE CODE RELIES ON IS WORSE THAN NONE:
  # it reports success about a proposition nobody cares about.
  #
  # sha1 of content, not the content itself, keeps keys short and readable in plan output.
  record_keys = { for r in var.records : "${r.name}|${r.type}|${substr(sha1(r.content), 0, 8)}" => r }
}

resource "cloudflare_dns_record" "this" {
  # Keyed by name+type+content-hash rather than index: an index key makes removing the first
  # record re-create every record after it, which for DKIM means a window where mail fails auth.
  for_each = local.record_keys

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  ttl     = each.value.ttl
  proxied = each.value.proxied
  comment = each.value.comment

  priority = each.value.type == "MX" ? each.value.priority : null
}

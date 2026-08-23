# ── Cloudflare Tunnel (cloudflared) — zero inbound ports for the on-prem cluster ──────────────
# A remotely-managed ("cloudflare" config_src) named tunnel + its ingress config + one proxied
# CNAME per hostname -> <tunnel-id>.cfargotunnel.com. cloudflared runs INSIDE the cluster (deployed
# separately) and dials OUT to Cloudflare using the run token computed below — so there is NO public
# IP and NO port-forward. See [[10-projects/production-cloudflare-tunnel]].
#
# Provider (cloudflare) is configured by the CALLER (terragrunt generates it; api_token comes from
# the CLOUDFLARE_API_TOKEN env var). This module declares no provider block.

# 32+ byte base64 secret that both defines the tunnel and seeds its run token.
resource "random_bytes" "tunnel_secret" {
  length = 35
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id    = var.account_id
  name          = var.tunnel_name
  config_src    = "cloudflare" # ingress managed here (below), not via a local YAML on the origin
  tunnel_secret = random_bytes.tunnel_secret.base64
}

# Ingress rules: hostname -> in-cluster service. v5 schema: `config` is an attribute and `ingress`
# is a LIST of objects; the LAST entry MUST be the catch-all (a rule with only `service`).
# ⚠️ CREATE-ONLY: the CF v5 provider CANNOT destroy this resource — `terraform destroy` removes it
# from STATE but the ingress config lingers in the Cloudflare API. It has no independent DELETE
# endpoint; it is purged only by deleting the TUNNEL (cascades the config) — see terraform_data
# .tunnel_purge below + scripts/cf-tunnel-purge.sh. Ref: [[30-references/cloudflare-tunnel-create-only-resources]].
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "ingress" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id

  config = {
    ingress = concat(
      [for r in var.routes : {
        hostname = r.hostname
        service  = r.service
      }],
      [{ service = "http_status:404" }], # required terminal catch-all
    )
  }
}

# Destroy-time API cleanup for the create-only config above. On `terraform destroy` this deletes the
# tunnel's connections + the tunnel itself via the CF API, which cascades the lingering ingress config
# so nothing is orphaned. Destroy provisioners may reference ONLY `self` (no path.module/vars), so the
# account/tunnel IDs are captured in triggers_replace and the API calls are INLINED (the equivalent
# standalone script is scripts/cf-tunnel-purge.sh, for manual/CI use). Runs BEFORE the tunnel resource
# is destroyed (this depends on it); TF's own tunnel delete afterward no-ops on the resulting 404.
# Requires CLOUDFLARE_API_TOKEN in the environment at destroy time.
resource "terraform_data" "tunnel_purge" {
  triggers_replace = {
    account_id = var.account_id
    tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      : "$${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN must be set to purge the tunnel}"
      base="https://api.cloudflare.com/client/v4/accounts/${self.triggers_replace.account_id}/cfd_tunnel/${self.triggers_replace.tunnel_id}"
      curl -fsS -X DELETE "$base/connections" -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" >/dev/null 2>&1 || true
      curl -fsS -X DELETE "$base"             -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" >/dev/null 2>&1 || true
      echo "purged cloudflared tunnel ${self.triggers_replace.tunnel_id} (create-only ingress config cascaded)"
    EOT
  }
}

# Existing records in the zone — read at plan time so we can avoid colliding with records this module
# does NOT own (e.g. a pre-provisioned `www` CNAME, GoDaddy's `_domainconnect`). Needs DNS Read.
data "cloudflare_dns_records" "existing" {
  zone_id = var.zone_id
}

locals {
  # Hostnames already claimed by a NON-tunnel record. Skipping these prevents the 81053 "record already
  # exists" apply failure. Our OWN records point at *.cfargotunnel.com, so they are NEVER in this map —
  # meaning the module never excludes/destroys its own records on a re-apply (that would flap).
  # A SET of names, not a map keyed by name.
  #
  # This was `r.name => true`, which asserts every record name in the zone is unique. DNS does not
  # work that way: a name may carry several records (an RRset) — multiple TXT for SPF/DKIM, several
  # A records for round-robin, MX. Terraform then fails the whole plan with
  #     Error: Duplicate object key ... Two different items produced the key "..."
  # pointing at this comprehension, in a module that has nothing to do with whatever added the
  # second record.
  #
  # It fired on 2026-08-24 when cert-manager's DNS-01 solver left two `_acme-challenge` TXT records
  # per host (one from the staging issuance, one from production). But ANY legitimate RRset would
  # have done it — the ACME records were simply the first to arrive.
  #
  # This value is only ever used as a membership test (see the `contains` below), so a set is both
  # the correct type and immune to duplicates.
  externally_claimed = toset([
    for r in data.cloudflare_dns_records.existing.result :
    r.name if !endswith(try(r.content, ""), ".cfargotunnel.com")
  ])
}

# One proxied (orange-cloud) CNAME per hostname -> the tunnel. NO A record / public IP.
# ttl = 1 ("automatic") is required for proxied records. A route whose hostname is already claimed by
# a non-tunnel record is SKIPPED (see local.externally_claimed) — so `apply` never 400s on a pre-existing
# record. NOTE: skipped hostnames are left as-is; the module defers to the existing record, it won't
# overwrite it. (A skipped host like `www` still reaches the tunnel if it CNAMEs to a tunnel host.)
resource "cloudflare_dns_record" "hostname" {
  for_each = {
    for r in var.routes : r.hostname => r
    if !contains(local.externally_claimed, r.hostname)
  }

  zone_id = var.zone_id
  name    = each.value.hostname
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
  comment = "Terraform: routes ${each.value.hostname} via cloudflared tunnel '${var.tunnel_name}'"
}

# cloudflared run token = base64(JSON{a: account_tag, t: tunnel_id, s: tunnel_secret}). Consumed as
# `cloudflared tunnel run --token <token>`. Store in Vault -> ESO for the in-cluster Deployment (Phase 3).
locals {
  tunnel_token = base64encode(jsonencode({
    a = var.account_id
    t = cloudflare_zero_trust_tunnel_cloudflared.main.id
    s = random_bytes.tunnel_secret.base64
  }))
}

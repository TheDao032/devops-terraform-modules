#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------
# Purge a Cloudflare `cloudflared` tunnel via the CF API.
#
# WHY: `cloudflare_zero_trust_tunnel_cloudflared_config` is CREATE-ONLY in the Cloudflare v5 provider
# — its Terraform `destroy` is a NO-OP, so the tunnel's ingress config lingers in the CF API. The
# config has no independent DELETE endpoint; it is removed only by deleting the TUNNEL, which cascades
# the config (and any routes/connections). This script does that cleanly + idempotently.
#
# Usage:   CLOUDFLARE_API_TOKEN=... ./cf-tunnel-purge.sh <account_id> <tunnel_id>
# ---------------------------------------------------------------------------------------------------
set -euo pipefail

ACCOUNT_ID="${1:?account_id required}"
TUNNEL_ID="${2:?tunnel_id required}"
: "${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN must be set (Cloudflare Tunnel:Edit)}"

BASE="https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}"
AUTH=(-H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")

echo "→ deleting inactive connections for tunnel ${TUNNEL_ID}"
curl -fsS -X DELETE "${BASE}/connections" "${AUTH[@]}" >/dev/null 2>&1 || true

echo "→ deleting tunnel ${TUNNEL_ID} (cascades the create-only ingress config)"
if curl -fsS -X DELETE "${BASE}" "${AUTH[@]}" >/dev/null 2>&1; then
  echo "✓ purged tunnel ${TUNNEL_ID}"
else
  echo "  (tunnel already gone / 404 — nothing to do)"
fi

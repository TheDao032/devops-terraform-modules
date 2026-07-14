# ── Secrets engine (optional) ────────────────────────────────────────────────
# KV-v2 at the environment path, so the policy paths (<env>/data/*, ...) resolve. Off by
# default — vault-roles callers mount KV via the separate vault-secrets stack; turn on
# (mount_kv = true) for a self-contained stack that owns the mount.
resource "vault_mount" "kv" {
  count       = var.mount_kv ? 1 : 0
  path        = var.environment
  type        = "kv"
  options     = { version = "2" }
  description = "KV v2 secrets engine for ${var.environment}"
}

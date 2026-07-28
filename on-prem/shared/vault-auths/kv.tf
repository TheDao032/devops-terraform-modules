# ── Secrets engine (optional) ────────────────────────────────────────────────
# KV-v2 mounted at local.kv_mount = the ORG ("fitmate"), with the environment as a folder
# inside it (local.path_root = "local/"). Secrets/policies/userpass all live under
# "<org>/data/<env>/...". Off by default — vault-roles callers mount KV via the separate
# vault-secrets stack; turn on (mount_kv = true) for a self-contained stack that owns the mount.
# The mount path flows out via the kv_mount_path output, which vault-secrets consumes.
resource "vault_mount" "kv" {
  count       = var.mount_kv ? 1 : 0
  path        = local.kv_mount
  type        = "kv"
  options     = { version = "2" }
  description = "KV v2 secrets engine for org '${local.kv_mount}' (env folder: ${local.path_root})"
}

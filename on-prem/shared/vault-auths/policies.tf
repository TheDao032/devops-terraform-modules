locals {
  policies_tmp_file = "${path.module}/templates/policies/policies.hcl.tftpl"

  # ONE KV engine per ORG: the engine is MOUNTED at "<org>" (e.g. "fitmate"), and the
  # environment is a FOLDER inside it ("<env>/", e.g. "local/"). A secret therefore lives at
  # "<org>/data/<env>/<path>" (mount "fitmate", key "local/..."). Back-compat: with no org,
  # mount at "<env>" and no sub-folder. kv_mount flows out via the kv_mount_path output.
  kv_mount = trimspace(var.org) != "" ? var.org : var.environment
  # env folder inside the mount, WITHOUT a trailing slash ("local") — so policy paths read
  # clearly as "<mount>/data/<path_root>/<path>". Empty when no org (legacy single-env layout).
  path_root = trimspace(var.org) != "" ? var.environment : ""
  # same, WITH a trailing slash ("local/") — for prepending to secret keys + userpass names,
  # which are bare paths (no separate slash in those consumers).
  key_prefix = local.path_root != "" ? "${local.path_root}/" : ""
}

# ── Authorization ─────────────────────────────────────────────────────────────
# Policies are the shared authZ layer — every auth method (approle in roles.tf, userpass in
# users.tf) attaches these by name. One policy per entry in var.roles, rendered from the
# shared template (same output as the vault-roles module).
resource "vault_policy" "main" {
  for_each = var.roles
  name     = each.key
  policy = fileexists(local.policies_tmp_file) ? templatefile(local.policies_tmp_file, {
    mount_path = local.kv_mount
    path_root  = local.path_root
    policies   = each.value
  }) : ""
}

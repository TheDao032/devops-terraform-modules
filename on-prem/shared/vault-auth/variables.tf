# vault-auth — one module for authentication + authorization. A drop-in SUPERSET of the older
# `vault-roles` module: the `roles` input + `roles` output are byte-compatible, so an existing
# vault-roles caller migrates by only changing `source`. Adds userpass (`users`) and an optional
# KV mount on top. In Vault, policies are the shared authZ layer; approle (machine) and userpass
# (human) are two auth methods that both attach those policies — this module models exactly that.

variable "environment" {
  description = "Environment name — the KV-v2 mount path and the prefix of every policy path."
  type        = string
}

variable "mount_kv" {
  description = <<-EOT
    Mount a KV-v2 engine at the environment path so policy paths (<env>/data/*, ...) resolve.
    Default false so this stays a drop-in for vault-roles callers (which mount KV via the
    separate vault-secrets stack). Set true for a self-contained stack that owns the mount.
  EOT
  type        = bool
  default     = false
}

variable "roles" {
  description = <<-EOT
    Policies + AppRole roles, keyed by name (IDENTICAL shape to the vault-roles module). Each
    entry creates: a `vault_policy` AND an approle role bound to it (token_policies = [name]).
      { <name> = [ { path, data_capabilities, metadata_capabilities,
                     delete_capabilities, destroy_capabilities } ] }
    Userpass users (below) reference these policy names. The approle backend is created
    unconditionally (byte-compatible with vault-roles); roles/secret_ids are per-entry.
  EOT
  type        = map(any)
  default     = {}
}

variable "users" {
  description = <<-EOT
    Userpass users (human logins), keyed by username:
      { <username> = { password = string, policies = list(string) } }
    `policies` must reference keys defined in `roles`. Passwords come from the caller's env
    (get_env) — never hardcode them. Userpass backend is created only when this map is non-empty.
  EOT
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags"
  type        = map(any)
  default     = {}
}

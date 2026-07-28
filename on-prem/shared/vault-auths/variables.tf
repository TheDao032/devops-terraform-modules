# vault-auths — one module for authentication + authorization. A drop-in SUPERSET of the older
# `vault-roles` module: the `roles` input + `roles` output are byte-compatible, so an existing
# vault-roles caller migrates by only changing `source`. Adds userpass (`users`) and an optional
# KV mount on top. In Vault, policies are the shared authZ layer; approle (machine) and userpass
# (human) are two auth methods that both attach those policies — this module models exactly that.

variable "environment" {
  description = "Environment name — the last segment of the KV-v2 mount path and every policy path."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string (it forms the KV mount path + policy prefix)."
  }
}

variable "org" {
  description = <<-EOT
    Organization/tenant name. When set, the KV-v2 mount + all policy paths are rooted at
    "<org>/<environment>" (e.g. "fitmate/local") instead of just "<environment>". Leave empty
    for the legacy "<environment>" layout (back-compatible with vault-roles callers).
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.org == "" || can(regex("^[a-z0-9]([a-z0-9._-]*[a-z0-9])?$", var.org))
    error_message = "org must be empty or a Vault-path-safe segment (lowercase alphanumeric, '.', '_', '-')."
  }
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
  type = map(list(object({
    path                  = string
    data_capabilities     = string
    metadata_capabilities = string
    delete_capabilities   = string
    destroy_capabilities  = string
  })))
  default = {}

  validation {
    condition = alltrue([
      for name, rules in var.roles : alltrue([
        for r in rules : length(trimspace(r.path)) > 0
      ])
    ])
    error_message = "roles.<name>[*].path must be a non-empty policy path (e.g. \"*\", \"dev/*\")."
  }

  validation {
    # Each *_capabilities is a comma-separated list of Vault policy verbs (or "deny").
    condition = alltrue([
      for name, rules in var.roles : alltrue([
        for r in rules : alltrue([
          for caps in [r.data_capabilities, r.metadata_capabilities, r.delete_capabilities, r.destroy_capabilities] :
          alltrue([
            for c in split(",", caps) :
            contains(["create", "read", "update", "delete", "list", "patch", "sudo", "deny"], trimspace(c))
          ])
        ])
      ])
    ])
    error_message = "roles.<name>[*].*_capabilities must be a comma-separated list of Vault verbs: create, read, update, delete, list, patch, sudo, deny."
  }
}

variable "users" {
  description = <<-EOT
    Userpass users (human logins), keyed by username:
      { <username> = { password = string, policies = list(string) } }
    `policies` must reference keys defined in `roles`. Passwords come from the caller's env
    (get_env) — never hardcode them. Userpass backend is created only when this map is non-empty.
  EOT
  type = map(object({
    password = string
    policies = list(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for name, cfg in var.users : length(cfg.policies) > 0])
    error_message = "users.<name>.policies must list at least one policy name."
  }

  validation {
    # Cross-variable check (Terraform >= 1.9): every referenced policy must be defined in `roles`.
    condition = alltrue([
      for name, cfg in var.users : alltrue([
        for p in cfg.policies : contains(keys(var.roles), p)
      ])
    ])
    error_message = "users.<name>.policies must reference names defined in var.roles."
  }
}

variable "tags" {
  description = "Resource tags applied where the provider supports them."
  type        = map(string)
  default     = {}
}

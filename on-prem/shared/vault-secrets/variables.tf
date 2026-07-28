variable "environment" {
  description = "Environment name."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "namespace" {
  description = "Vault namespace."
  type        = string
  default     = "default"

  validation {
    condition     = length(trimspace(var.namespace)) > 0
    error_message = "namespace must be a non-empty string."
  }
}

variable "kv_mount_path" {
  description = "KV-v2 mount path the secrets are written under (mount = this value) — the org, e.g. 'fitmate'."
  type        = string
  default     = ""
}

variable "path_prefix" {
  description = "Prepended to every secret key so it lands under the env folder, e.g. 'local/'. From vault-auths's secret_path_prefix output. Empty = write keys directly under the mount."
  type        = string
  default     = ""
}

# variable "database" {
#   type    = map(any)
#   default = {}
# }
#
# variable "vault" {
#   type    = map(any)
#   default = {}
# }
#
# variable "jenkins" {
#   type    = map(any)
#   default = {}
# }
#
# variable "grafana" {
#   type    = map(any)
#   default = {}
# }
#
# variable "kafka" {
#   type    = map(any)
#   default = {}
# }
#
# variable "k3s" {
#   type    = map(any)
#   default = {}
# }
#
# variable "keycloak" {
#   type    = map(any)
#   default = {}
# }
#
# variable "ldap" {
#   type    = map(any)
#   default = {}
# }
#
# variable "query_service" {
#   type    = map(any)
#   default = {}
# }
#
# variable "default_service_secrets" {
#   type    = map(any)
#   default = {}
# }
#
# variable "global" {
#   type    = map(any)
#   default = {}
# }

variable "secrets" {
  description = <<-EOT
    Secrets to write, keyed by KV path -> { key = value }. Values are HETEROGENEOUS: a plain
    string/number, OR the `_RANDOM_` marker convention (e.g. "{ _RANDOM_ = 18 }") which the
    module replaces with a generated random_password of the given length. Because of this mixed
    convention the map stays `any` — do NOT force a strict value type or the marker strings break.

    NOTE: NOT marked `sensitive` — main.tf derives `local.secrets` from this var and uses it as a
    `for_each` key on vault_kv_secret_v2, and Terraform forbids sensitive values as for_each keys.
    Marking it sensitive makes the module fail to plan.
  EOT
  # intentionally any: _RANDOM_ marker strings mix with plain string/number values per path
  type    = map(any)
  default = {}

  validation {
    condition     = can(keys(var.secrets))
    error_message = "secrets must be a map of KV path -> credential map."
  }
}

variable "tags" {
  description = "Resource tags applied where the provider supports them."
  type        = map(string)
  default     = {}
}

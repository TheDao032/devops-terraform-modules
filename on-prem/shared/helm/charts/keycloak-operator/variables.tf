variable "enabled" {
  description = "1 = deploy the operator + Keycloak CR, 0 = skip (mirrors the other addon modules)."
  type        = number
  default     = 1

  validation {
    condition     = contains([0, 1], var.enabled)
    error_message = "enabled must be 0 or 1."
  }
}

variable "environment" {
  description = "Environment name (local/prod)."
  type        = string
}

variable "namespace" {
  description = "Namespace for the operator + Keycloak instance. MUST be 'keycloak' — the vendored operator manifest (files/operator-*.yml) hardcodes that namespace."
  type        = string
  default     = "keycloak"

  validation {
    condition     = var.namespace == "keycloak"
    error_message = "namespace must be 'keycloak' (the vendored operator manifest is namespace-pinned; re-vendor it to change)."
  }
}

variable "operator_manifest_file" {
  description = "Filename under files/ of the vendored Keycloak Operator manifest (Deployment + RBAC + SA + Service), pinned to a release."
  type        = string
  default     = "operator-26.7.0.yml"
}

# ── Keycloak CR config ──
variable "keycloak_conf" {
  description = "Keycloak custom-resource config."
  type = object({
    hostname  = string # public hostname the gateway routes to, e.g. keycloak.k3s.local
    instances = optional(number, 1)
    image     = optional(string) # override the Keycloak image (default = operator's bundled version)
    db = object({
      host     = string # Postgres host — the coordinator DIRECT :5432 (NOT pgbouncer)
      port     = optional(number, 5432)
      database = optional(string, "keycloak")
    })
  })
}

# DB credentials (from Vault via the terragrunt vault-secrets dependency) → written into the
# keycloak-db Secret the CR references. Sensitive; not for_each keys, so safe to mark sensitive.
variable "db_username" {
  description = "Keycloak DB role (keycloak_app)."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Keycloak DB role password."
  type        = string
  sensitive   = true
}

# Kube provider passthrough — kept for interface parity with the other addon modules; the
# ACTUAL provider is the root-inherited one (see providers.tf).
variable "host" {
  type    = string
  default = ""
}
variable "client_key" {
  type    = string
  default = ""
}
variable "client_certificate" {
  type    = string
  default = ""
}
variable "cluster_ca_certificate" {
  type    = string
  default = ""
}
variable "token" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(any)
  default = {}
}

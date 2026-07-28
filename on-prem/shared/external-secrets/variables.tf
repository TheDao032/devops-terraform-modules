variable "environment" {
  description = "Environment name — passed through to the secrets-stored sub-modules and rendered into templates."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "org" {
  description = "Organization/tenant. When set, the SecretStore KV path becomes \"<org>/<environment>\" (matches vault-auths); empty = legacy \"<environment>\"."
  type        = string
  default     = ""
}

variable "local" {
  description = <<-EOT
    Configuration for the `local` namespace ExternalSecret. Freeform: the module reads
    `.common` (which must carry `.namespace`) and `.secret`, then hands the whole map to a
    templatefile. Shape varies per secret set, so it stays `any`.
  EOT
  # intentionally any: freeform ExternalSecret config consumed by templatefile via .common/.secret
  type    = map(any)
  default = {}

  validation {
    condition     = can(keys(var.local))
    error_message = "local must be a map."
  }
}

variable "gitops" {
  description = <<-EOT
    Configuration for the `gitops` namespace ExternalSecret. Freeform: the module reads
    `.common` (which must carry `.namespace`) and `.secret`, then hands the whole map to a
    templatefile. Shape varies per secret set, so it stays `any`.
  EOT
  # intentionally any: freeform ExternalSecret config consumed by templatefile via .common/.secret
  type    = map(any)
  default = {}

  validation {
    condition     = can(keys(var.gitops))
    error_message = "gitops must be a map."
  }
}

variable "tags" {
  description = "Resource tags applied where the provider supports them."
  type        = map(string)
  default     = {}
}

variable "host" {
  description = "Kubernetes API server URL for the kubectl/helm providers."
  type        = string

  validation {
    condition     = length(trimspace(var.host)) > 0
    error_message = "host must be a non-empty Kubernetes API server URL."
  }
}

# NOTE: `token` vs `client_certificate`/`client_key` are MUTUALLY-EXCLUSIVE auth methods —
# a cert-auth cluster (k3s) passes the certs + an EMPTY token; a token-auth cluster (EKS,
# service-account) passes the token + EMPTY certs. So NONE of these may be validated
# non-empty (doing so breaks the other auth method). The kubectl/helm provider surfaces a
# real auth error if all are missing.
variable "client_key" {
  description = "PEM-encoded client private key for Kubernetes API auth (empty for token-auth clusters)."
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "PEM-encoded client certificate for Kubernetes API auth (empty for token-auth clusters)."
  type        = string
}

variable "cluster_ca_certificate" {
  description = "PEM-encoded cluster CA certificate used to verify the Kubernetes API server (may be empty)."
  type        = string
}

variable "token" {
  description = "Bearer token for Kubernetes API auth (empty for cert-auth clusters like k3s)."
  type        = string
  sensitive   = true
}

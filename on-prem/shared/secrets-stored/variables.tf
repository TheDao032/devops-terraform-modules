variable "environment" {
  description = "Environment name — the last segment of the KV mount path the SecretStore reads from."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "org" {
  description = "Organization/tenant. When set, the SecretStore KV path is \"<org>/<environment>\" (matches vault-auths); empty = legacy \"<environment>\"."
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Target namespace — also selects the per-namespace template dir (namespaces/<namespace>/*.tftpl)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid Kubernetes namespace (RFC1123 label: lowercase alphanumeric or '-', start/end alphanumeric)."
  }
}

variable "enabled" {
  description = "Enable gate for the templated manifests (1 = apply when the template file exists)."
  type        = number
  default     = 1

  validation {
    condition     = contains([0, 1], var.enabled)
    error_message = "enabled must be 0 or 1."
  }
}

variable "disabled" {
  description = "Disable sentinel used by the fileexists() enable gates (0 = skip)."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1], var.disabled)
    error_message = "disabled must be 0 or 1."
  }
}

# variable "name" {
#   type = string
# }

variable "parameters" {
  # intentionally any: freeform config passed straight into templatefile() for the approle-secret
  # and secret-store manifests; shape varies per namespace template and is not consumed as a map here.
  description = "Chart/template parameters passed to templatefile() for the per-namespace manifests."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Resource tags applied where the provider supports them."
  type        = map(string)
  default     = {}
}

variable "host" {
  description = "Kubernetes API server URL for the provider."
  type        = string

  validation {
    condition     = length(trimspace(var.host)) > 0
    error_message = "host must be a non-empty Kubernetes API server URL."
  }
}

variable "client_key" {
  description = "PEM-encoded client key for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "PEM-encoded client certificate for Kubernetes API authentication."
  type        = string
}

variable "cluster_ca_certificate" {
  description = "PEM-encoded cluster CA certificate for verifying the Kubernetes API server."
  type        = string
}

variable "token" {
  description = "Bearer token for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

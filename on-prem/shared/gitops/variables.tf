variable "environment" {
  description = "Environment name — rendered into the app/ex-secret templates."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "namespace" {
  description = "Kubernetes namespace the rendered manifests target."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid RFC 1123 DNS label (lowercase alphanumeric and '-', max 63 chars)."
  }
}

variable "enabled" {
  description = "Toggle (1 = create resources, 0 = skip). Gates the count on the rendered kubectl manifests."
  type        = number
  default     = 1

  validation {
    condition     = contains([0, 1], var.enabled)
    error_message = "enabled must be 0 or 1."
  }
}

variable "name" {
  description = "App name — selects the apps/<name>/ template dir (application.helm.yml.tftpl, ex-secrets.yml.tftpl)."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must be a non-empty app directory name under apps/."
  }
}

variable "parameters" {
  description = <<-EOT
    Chart parameters handed straight to templatefile for apps/<name>/*.tftpl. Shape is
    per-app and freeform, so it stays `any`.
  EOT
  # intentionally any: freeform per-app template parameters consumed by templatefile
  type    = map(any)
  default = {}

  validation {
    condition     = can(keys(var.parameters))
    error_message = "parameters must be a map."
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

# Generic helm wrapper module. `parameters`/`tags` are freeform maps piped straight into
# templatefile()/helm_release.values — they MUST stay `any`. `enabled`/`disabled` are
# count-style ints (0/1) driving resource count. `chart`/`values_type` are nullable by contract.

variable "environment" {
  description = "Environment name — passed into every templatefile() render as `environment`."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "namespace" {
  description = "Kubernetes namespace the helm release and pre-helm manifests deploy into."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid RFC 1123 DNS label (lowercase alphanumeric and '-')."
  }
}

variable "enabled" {
  description = "Count-style toggle: 1 creates the helm_release (and gated manifests), 0 disables it."
  type        = number
  default     = 1

  validation {
    condition     = contains([0, 1], var.enabled)
    error_message = "enabled must be 0 or 1 (used as a resource count)."
  }
}

variable "disabled" {
  description = "Count-style off value used when a fileexists()-gated manifest should not be created."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1], var.disabled)
    error_message = "disabled must be 0 or 1 (used as a resource count)."
  }
}

variable "chart" {
  description = "Local chart path selector. When null the release uses a local ./charts/<name> dir; otherwise the remote repository chart."
  type        = string
  default     = null
}

variable "name" {
  description = "Helm release name and the ./charts/<name> subdirectory selector."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must be a non-empty string (it selects the chart dir and names the release)."
  }
}

variable "repository" {
  description = "Helm chart repository URL."
  type        = string

  validation {
    condition     = length(trimspace(var.repository)) > 0
    error_message = "repository must be a non-empty string."
  }
}

variable "chart_version" {
  description = "Helm chart version to install."
  type        = string

  validation {
    condition     = length(trimspace(var.chart_version)) > 0
    error_message = "chart_version must be a non-empty string."
  }
}

variable "values_type" {
  description = "Selects the values template variant: values.<values_type>.yml.tftpl. Null uses the default values.yml.tftpl."
  type        = string
  default     = null
}

variable "parameters" {
  # intentionally any: freeform helm/template values piped straight into templatefile()/helm values
  description = "Chart's parameters — freeform map rendered into the chart's values/manifest templates."
  type        = map(any)
  default     = {}
}

variable "tags" {
  # intentionally any: freeform metadata map
  description = "Tags"
  type        = map(any)
  default     = {}
}

variable "host" {
  description = "Kubernetes API server host (inherited provider context)."
  type        = string

  validation {
    condition     = length(trimspace(var.host)) > 0
    error_message = "host must be a non-empty string."
  }
}

variable "client_key" {
  description = "PEM-encoded client private key for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "PEM-encoded client certificate for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "PEM-encoded cluster CA certificate used to verify the Kubernetes API server."
  type        = string
  sensitive   = true
}

variable "token" {
  description = "Bearer token for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

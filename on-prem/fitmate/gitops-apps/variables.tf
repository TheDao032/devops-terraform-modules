variable "environment" {
  description = "Environment name — passed through to the gitops sub-module."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "pod_restart_collector" {
  # intentionally any: apps.tf splits this into freeform .docker/.github/.common/.argocd/.secret
  # config blocks whose shapes vary and are handed to the gitops sub-module as opaque parameters.
  description = "Configuration for the pod-restart-collector app (docker/github/common/argocd/secret blocks)."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.pod_restart_collector))
    error_message = "pod_restart_collector must be a map/object (keyed by config block: docker, github, common, argocd, secret)."
  }
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

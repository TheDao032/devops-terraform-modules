variable "environment" {
  description = "Environment name — used as the default namespace and passed through to the ../gitops submodule."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "pod_restart_collector" {
  description = <<-EOT
    Configuration for the pod-restart-collector GitOps app. Structured object consumed by the
    ../gitops submodule via `parameters` (keys: common, secret, argocd, docker, github). Optional
    sub-blocks default to {} so partially-specified callers keep working.
      common = { app_name, namespace }
      secret = { store_name, name }
      docker = { secret_name, organization }
      argocd = { namespace }
      github = { secret_name, url, gitops_repo }
  EOT
  type = object({
    common = optional(object({
      app_name  = string
      namespace = string
    }))
    secret = optional(object({
      store_name = optional(string)
      name       = optional(string)
    }), {})
    docker = optional(object({
      secret_name  = optional(string)
      organization = optional(string)
    }), {})
    argocd = optional(object({
      namespace = optional(string)
    }), {})
    github = optional(object({
      secret_name = optional(string)
      url         = optional(string)
      gitops_repo = optional(string)
    }), {})
  })
  default = {}

  validation {
    # common is required in practice (apps.tf reads .common.app_name / .namespace); guard when supplied.
    condition     = var.pod_restart_collector.common == null ? true : length(trimspace(var.pod_restart_collector.common.app_name)) > 0
    error_message = "pod_restart_collector.common.app_name must be a non-empty string."
  }

  validation {
    condition     = var.pod_restart_collector.common == null ? true : length(trimspace(var.pod_restart_collector.common.namespace)) > 0
    error_message = "pod_restart_collector.common.namespace must be a non-empty string (Kubernetes namespace)."
  }
}

variable "tags" {
  description = "Resource tags passed through to the ../gitops submodule."
  type        = map(string)
  default     = {}
}

variable "host" {
  description = "Kubernetes API server URL for the target cluster."
  type        = string

  validation {
    condition     = can(regex("^https?://", var.host))
    error_message = "host must be an http(s):// URL for the Kubernetes API server."
  }
}

variable "client_key" {
  description = "Base64-encoded client private key for Kubernetes API auth."
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "Base64-encoded client certificate for Kubernetes API auth."
  type        = string
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate for the Kubernetes API server."
  type        = string
  sensitive   = true
}

variable "token" {
  description = "Bearer token for Kubernetes API auth."
  type        = string
  sensitive   = true
}

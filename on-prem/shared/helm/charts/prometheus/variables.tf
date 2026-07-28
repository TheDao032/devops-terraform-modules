variable "environment" {
  description = "Environment name."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "chart_version" {
  description = "kube-prometheus-stack helm chart version."
  type        = string

  validation {
    condition     = length(trimspace(var.chart_version)) > 0
    error_message = "chart_version must be a non-empty string."
  }
}

variable "namespace" {
  description = "Namespace the Prometheus stack deploys into."
  type        = string
  default     = "monitoring"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid RFC 1123 DNS label."
  }
}

variable "helm_release_name" {
  description = "Prometheus's helm release name"
  type        = string
  default     = "prometheus"

  validation {
    condition     = length(trimspace(var.helm_release_name)) > 0
    error_message = "helm_release_name must be a non-empty string."
  }
}

variable "helm_release_chart" {
  description = "Prometheus's helm release chart name"
  type        = string
  default     = "kube-prometheus-stack"

  validation {
    condition     = length(trimspace(var.helm_release_chart)) > 0
    error_message = "helm_release_chart must be a non-empty string."
  }
}

variable "helm_repository" {
  description = "Prometheus's helm repository"
  type        = string
  default     = "https://prometheus-community.github.io/helm-charts"

  validation {
    condition     = length(trimspace(var.helm_repository)) > 0
    error_message = "helm_repository must be a non-empty string."
  }
}

variable "prometheus" {
  # intentionally any: freeform values rendered into values.yml.tftpl (.ingress.* accessed by key)
  description = "Prometheus Ingress Data — freeform map; must expose .ingress.strip_prefix and .ingress.prefix."
  type        = map(any)
  default     = {}
}

variable "alertmanager" {
  # intentionally any: freeform values rendered into values.yml.tftpl (.ingress.* accessed by key)
  description = "Alertmanager Ingress Data — freeform map; must expose .ingress.strip_prefix and .ingress.prefix."
  type        = map(any)
  default     = {}
}

variable "grafana" {
  # intentionally any: freeform values rendered into values.yml.tftpl (.ingress.* accessed by key)
  description = "Grafana Ingress Data — freeform map; must expose .ingress.strip_prefix and .ingress.prefix."
  type        = map(any)
  default     = {}
}

variable "external_server_ip" {
  description = "External server ip"
  type        = string

  validation {
    condition     = length(trimspace(var.external_server_ip)) > 0
    error_message = "external_server_ip must be a non-empty string."
  }
}

variable "internal_loki_server" {
  description = "Internal Loki Server"
  type        = string
  default     = ""
}

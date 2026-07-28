variable "namespace" {
  description = "Kafka's namespace"
  type        = string
  default     = "default"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid RFC 1123 DNS label."
  }
}

variable "cluster_name" {
  description = "Cluster's name"
  type        = string
  default     = "local"

  validation {
    condition     = length(trimspace(var.cluster_name)) > 0
    error_message = "cluster_name must be a non-empty string."
  }
}

variable "helm_repository" {
  description = "Repository of Kafka"
  type        = string
  default     = "https://charts.bitnami.com/bitnami"

  validation {
    condition     = length(trimspace(var.helm_repository)) > 0
    error_message = "helm_repository must be a non-empty string."
  }
}


variable "loki_helm_release_name" {
  description = "Kafka's helm release name"
  type        = string
  default     = "kafka"

  validation {
    condition     = length(trimspace(var.loki_helm_release_name)) > 0
    error_message = "loki_helm_release_name must be a non-empty string."
  }
}

variable "loki_helm_release_chart" {
  description = "Kafka's helm release chart name"
  type        = string
  default     = "kafka"

  validation {
    condition     = length(trimspace(var.loki_helm_release_chart)) > 0
    error_message = "loki_helm_release_chart must be a non-empty string."
  }
}

variable "loki_chart_version" {
  description = "Loki's Helm Chart Version"
  type        = string
  default     = "30.1.5"

  validation {
    condition     = length(trimspace(var.loki_chart_version)) > 0
    error_message = "loki_chart_version must be a non-empty string."
  }
}

variable "alloy_helm_release_name" {
  description = "Alloy's helm release name"
  type        = string
  default     = "kafka"

  validation {
    condition     = length(trimspace(var.alloy_helm_release_name)) > 0
    error_message = "alloy_helm_release_name must be a non-empty string."
  }
}

variable "alloy_helm_release_chart" {
  description = "Kafka's helm release chart name"
  type        = string
  default     = "kafka"

  validation {
    condition     = length(trimspace(var.alloy_helm_release_chart)) > 0
    error_message = "alloy_helm_release_chart must be a non-empty string."
  }
}

variable "alloy_chart_version" {
  description = "Helm Chart Version"
  type        = string
  default     = "30.1.5"

  validation {
    condition     = length(trimspace(var.alloy_chart_version)) > 0
    error_message = "alloy_chart_version must be a non-empty string."
  }
}

variable "common_conf" {
  # intentionally any: freeform values rendered into the loki values template (.ingress.* accessed by key)
  description = "Loki Conf Data — freeform map; must expose .ingress.strip_prefix and .ingress.prefix."
  type        = map(any)
  default     = {}
}

variable "microservice_conf" {
  # intentionally any: freeform values rendered into the loki values template
  description = "Loki Conf Data — freeform map for the microservice deployment mode."
  type        = map(any)
  default     = {}
}

variable "monolithic_conf" {
  # intentionally any: freeform values rendered into the loki values template
  description = "Loki Conf Data — freeform map for the monolithic deployment mode."
  type        = map(any)
  default     = {}
}

variable "scalable_conf" {
  # intentionally any: freeform values rendered into the loki values template
  description = "Loki Conf Data — freeform map for the scalable deployment mode."
  type        = map(any)
  default     = {}
}

variable "auth_conf" {
  # intentionally any: freeform credential map rendered into loki/alloy values templates
  description = "alloy Conf Data — freeform map of Loki auth credentials."
  type        = map(any)
  default     = {}
  sensitive   = true
}

variable "alloy_conf" {
  # intentionally any: freeform values rendered into the alloy values template
  description = "alloy Conf Data — freeform map."
  type        = map(any)
  default     = {}
}

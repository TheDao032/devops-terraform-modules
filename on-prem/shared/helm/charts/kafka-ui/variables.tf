variable "chart_version" {
  description = "Helm Chart Version"
  type        = string

  validation {
    condition     = length(trimspace(var.chart_version)) > 0
    error_message = "chart_version must be a non-empty string."
  }
}

variable "image_tag" {
  description = "Kafka's Docker image tag version"
  type        = string

  validation {
    condition     = length(trimspace(var.image_tag)) > 0
    error_message = "image_tag must be a non-empty string."
  }
}

variable "namespace" {
  description = "KafkaUI's namespace"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid RFC 1123 DNS label."
  }
}

variable "helm_release_name" {
  description = "KafkaUI's helm release name"
  type        = string
  default     = "kafka-ui"

  validation {
    condition     = length(trimspace(var.helm_release_name)) > 0
    error_message = "helm_release_name must be a non-empty string."
  }
}

variable "helm_release_chart" {
  description = "KafkaUI's helm release chart name"
  type        = string
  default     = "kafka-ui"

  validation {
    condition     = length(trimspace(var.helm_release_chart)) > 0
    error_message = "helm_release_chart must be a non-empty string."
  }
}

variable "helm_repository" {
  description = "Repository of KafkaUI"
  type        = string
  default     = "https://provectus.github.io/kafka-ui-charts"

  validation {
    condition     = length(trimspace(var.helm_repository)) > 0
    error_message = "helm_repository must be a non-empty string."
  }
}

variable "kafka_ui_host" {
  description = "Repository of Kafka"
  type        = string

  validation {
    condition     = length(trimspace(var.kafka_ui_host)) > 0
    error_message = "kafka_ui_host must be a non-empty string."
  }
}

variable "kafka_ui_conf" {
  # intentionally any: freeform values rendered into the chart values template (ingress.* accessed by key)
  description = "Kafka UI Conf Data — freeform map rendered into values.yml.tftpl; must expose .ingress.strip_prefix and .ingress.prefix."
  type        = map(any)
  default     = {}
}

variable "keycloak" {
  # intentionally any: freeform helm/template values
  description = "KeyCloak Configuration — freeform map."
  type        = map(any)
  default     = {}
}

variable "keycloak_kafka_ui_credentials" {
  # intentionally any: freeform helm/template values (rendered into values as `keycloak`)
  description = "KeyCloak Kafka UI Credentials — freeform map of OIDC client credentials."
  type        = map(any)
  default     = {}
  sensitive   = true
}

variable "internal_bootstrap_server" {
  description = "Internal Bootstrap Server"
  type        = string

  validation {
    condition     = length(trimspace(var.internal_bootstrap_server)) > 0
    error_message = "internal_bootstrap_server must be a non-empty string."
  }
}

variable "internal_bootstrap_server_port" {
  description = "Internal Bootstrap Server"
  type        = number

  validation {
    condition     = var.internal_bootstrap_server_port >= 1 && var.internal_bootstrap_server_port <= 65535
    error_message = "internal_bootstrap_server_port must be a valid TCP port (1..65535)."
  }
}

variable "environment" {
  description = "Environment"
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

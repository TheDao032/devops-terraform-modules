variable "environment" {
  description = "Environment name rendered into the chart values template."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "chart_version" {
  description = "Keycloak helm chart version."
  type        = string

  validation {
    condition     = length(trimspace(var.chart_version)) > 0
    error_message = "chart_version must be a non-empty string."
  }
}

variable "namespace" {
  description = "Namespace the Keycloak release deploys into."
  type        = string
  default     = "default"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid RFC 1123 DNS label."
  }
}

variable "helm_release_name" {
  description = "Prometheus's helm release name"
  type        = string
  default     = "keycloak"

  validation {
    condition     = length(trimspace(var.helm_release_name)) > 0
    error_message = "helm_release_name must be a non-empty string."
  }
}

variable "helm_release_chart" {
  description = "Prometheus's helm release chart name"
  type        = string
  default     = "bitnami-keycloak"

  validation {
    condition     = length(trimspace(var.helm_release_chart)) > 0
    error_message = "helm_release_chart must be a non-empty string."
  }
}

variable "helm_repository" {
  description = "Prometheus's helm repository"
  type        = string
  default     = "https://charts.bitnami.com/bitnami"

  validation {
    condition     = length(trimspace(var.helm_repository)) > 0
    error_message = "helm_repository must be a non-empty string."
  }
}

variable "external_server_ip" {
  description = "External server ip"
  type        = string

  validation {
    condition     = length(trimspace(var.external_server_ip)) > 0
    error_message = "external_server_ip must be a non-empty string."
  }
}

variable "vault_mount_path" {
  description = "Vault mount path"
  type        = string

  validation {
    condition     = length(trimspace(var.vault_mount_path)) > 0
    error_message = "vault_mount_path must be a non-empty string."
  }
}

variable "keycloak_conf" {
  # intentionally any: freeform values rendered into values.yml.tftpl (.ingress.* and .storage.class_name accessed by key)
  description = "keycloak configurations — freeform map; must expose .ingress.strip_prefix, .ingress.prefix, .storage.class_name."
  type        = map(any)
}

variable "keycloak_host" {
  description = "keycloak host name"
  type        = string

  validation {
    condition     = length(trimspace(var.keycloak_host)) > 0
    error_message = "keycloak_host must be a non-empty string."
  }
}

variable "keycloak_params" {
  # intentionally any: freeform Vault-sourced params
  description = "keycloak Vault Params — freeform map."
  type        = map(any)
  sensitive   = true
}

variable "keycloak_kafkaui_creds" {
  # intentionally any: freeform credential map
  description = "keycloak KafkaUI Creds — freeform map of client credentials."
  type        = map(any)
  sensitive   = true
}

variable "realm" {
  # intentionally any: freeform values rendered into the chart values template
  description = "keycloak Realm Configurations — freeform map."
  type        = map(any)
}

variable "clients" {
  # intentionally any: freeform values rendered into the chart values template
  description = "keycloak Clients Configuration — freeform map."
  type        = map(any)
}

variable "user_federations" {
  # intentionally any: freeform values rendered into the chart values template
  description = "keycloak User Federations Configuration — freeform map."
  type        = map(any)
}

variable "tags" {
  # intentionally any: freeform metadata map
  description = "Resource tags."
  type        = map(any)
  default     = {}
}

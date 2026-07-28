variable "chart_version" {
  description = "Helm chart version."
  type        = string
  default     = "30.1.5"

  validation {
    condition     = length(trimspace(var.chart_version)) > 0
    error_message = "chart_version must be a non-empty version string."
  }
}

variable "image_tag" {
  description = "Kafka's Docker image tag version."
  type        = string
  default     = "3.8.0-debian-12-r6"

  validation {
    condition     = length(trimspace(var.image_tag)) > 0
    error_message = "image_tag must be a non-empty image tag."
  }
}

variable "namespace" {
  description = "Kafka's namespace."
  type        = string
  default     = "default"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid RFC 1123 DNS label (lowercase alphanumeric and '-', max 63 chars)."
  }
}

variable "helm_release_name" {
  description = "Kafka's helm release name."
  type        = string
  default     = "kafka"

  validation {
    condition     = length(trimspace(var.helm_release_name)) > 0
    error_message = "helm_release_name must be a non-empty string."
  }
}

variable "helm_release_chart" {
  description = "Kafka's helm release chart name."
  type        = string
  default     = "kafka"

  validation {
    condition     = length(trimspace(var.helm_release_chart)) > 0
    error_message = "helm_release_chart must be a non-empty string."
  }
}

variable "helm_repository" {
  description = "Repository of Kafka."
  type        = string
  default     = "https://charts.bitnami.com/bitnami"

  validation {
    condition     = length(trimspace(var.helm_repository)) > 0
    error_message = "helm_repository must be a non-empty repository URL."
  }
}

variable "nginx_gateway_fabric" {
  description = "NGINX Gateway Fabric controller config data (freeform, template-consumed)."
  # intentionally any: freeform controller config map, shape varies per install
  type    = map(any)
  default = {}

  validation {
    condition     = can(keys(var.nginx_gateway_fabric))
    error_message = "nginx_gateway_fabric must be a map."
  }
}

variable "traefik_gateway_api" {
  description = "Traefik Gateway API controller config data (freeform, template-consumed)."
  # intentionally any: freeform controller config map, shape varies per install
  type    = map(any)
  default = {}

  validation {
    condition     = can(keys(var.traefik_gateway_api))
    error_message = "traefik_gateway_api must be a map."
  }
}

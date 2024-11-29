variable "environment" {
  type = string
}

variable "chart_version" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "helm_release_name" {
  description = "Prometheus's helm release name"
  type        = string
  default     = "keycloak"
}

variable "helm_release_chart" {
  description = "Prometheus's helm release chart name"
  type        = string
  default     = "bitnami-keycloak"
}

variable "helm_repository" {
  description = "Prometheus's helm repository"
  type        = string
  default     = "https://charts.bitnami.com/bitnami"
}

variable "external_server_ip" {
  description = "External server ip"
  type        = string
}

variable "keycloak_host" {
  description = "Grafana server ip"
  type        = string
}

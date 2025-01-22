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

variable "vault_mount_path" {
  description = "Vault mount path"
  type        = string
}

variable "keycloak_conf" {
  description = "keycloak configurations"
  type        = map(any)
}

variable "keycloak_host" {
  description = "keycloak host name"
  type        = string
}

variable "keycloak_params" {
  description = "keycloak Vault Params"
  type        = map(any)
}

variable "keycloak_kafkaui_creds" {
  description = "keycloak KafkaUI Creds"
  type        = map(any)
}

variable "realm" {
  description = "keycloak Realm Configurations"
  type        = map(any)
}

variable "clients" {
  description = "keycloak Clients Configuration"
  type        = map(any)
}

variable "user_federations" {
  description = "keycloak User Federations Configuration"
  type        = map(any)
}

variable "tags" {
  type    = map(any)
  default = {}
}

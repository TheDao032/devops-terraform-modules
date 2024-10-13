variable "chart_version" {
  type    = string
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "server_conf" {
  description = "Server Conf Data"
  type        = map(any)
  default     = {}
}

variable "ui_conf" {
  description = "Vault UI Conf Data"
  type        = map(any)
  default     = {}
}

variable "helm_release_name" {
  description = "Kafka's helm release name"
  type    = string
  default = "hashicorp"
}

variable "helm_release_chart" {
  description = "Kafka's helm release chart name"
  type    = string
  default = "vault"
}

variable "helm_repository" {
  description = "Repository of Kafka"
  type    = string
  default = "https://helm.releases.hashicorp.com"
}

variable "vault_hosts" {
  description = "Repository of Kafka"
  type    = list(map(any))
  default = []
}

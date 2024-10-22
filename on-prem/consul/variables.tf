variable "chart_version" {
  description = "Helm chart version"
  type    = string
  default = "1.5.3"
}

variable "namespace" {
  description = "Vault namespace"
  type    = string
  default = "vault"
}

variable "helm_release_name" {
  description = "Vault's helm release name"
  type    = string
  default = "hashicorp"
}

variable "helm_release_chart" {
  description = "Vault's helm release chart name"
  type    = string
  default = "consul"
}

variable "helm_repository" {
  description = "Repository of Vault"
  type    = string
  default = "https://helm.releases.hashicorp.com"
}

variable "server_conf" {
  description = "Server Conf Data"
  type        = map(any)
  default     = {}
}

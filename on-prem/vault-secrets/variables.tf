variable "environment" {
  type = string
}

variable "kv_secret_path" {
  description = "KV secret path"
  type    = string
  default = "kv"
}

variable "namespace" {
  description = "Vault namespace"
  type    = string
  default = "default"
}

variable "secrets" {
  type    = map(any)
  default = {}
}

variable "tags" {
  type    = map(any)
  default = {}
}

# variable "server_conf" {
#   description = "Server Conf Data"
#   type        = map(any)
#   default     = {}
# }
#
# variable "ui_conf" {
#   description = "Vault UI Conf Data"
#   type        = map(any)
#   default     = {}
# }
#
# variable "helm_release_name" {
#   description = "Vault's helm release name"
#   type    = string
#   default = "hashicorp"
# }
#
# variable "helm_release_chart" {
#   description = "Vault's helm release chart name"
#   type    = string
#   default = "vault"
# }
#
# variable "helm_repository" {
#   description = "Repository of Vault"
#   type    = string
#   default = "https://helm.releases.hashicorp.com"
# }
#
# variable "vault_hosts" {
#   description = "Repository of Vault"
#   type    = list(any)
#   default = [
#     {
#       host = "traefik.vault.local.com"
#       paths = []
#     }
#   ]
# }

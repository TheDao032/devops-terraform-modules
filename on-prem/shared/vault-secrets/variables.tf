variable "environment" {
  type = string
}

variable "namespace" {
  description = "Vault namespace"
  type        = string
  default     = "default"
}

variable "kv_mount_path" {
  type    = string
  default = ""
}

# variable "database" {
#   type    = map(any)
#   default = {}
# }
#
# variable "vault" {
#   type    = map(any)
#   default = {}
# }
#
# variable "jenkins" {
#   type    = map(any)
#   default = {}
# }
#
# variable "grafana" {
#   type    = map(any)
#   default = {}
# }
#
# variable "kafka" {
#   type    = map(any)
#   default = {}
# }
#
# variable "k3s" {
#   type    = map(any)
#   default = {}
# }
#
# variable "keycloak" {
#   type    = map(any)
#   default = {}
# }
#
# variable "ldap" {
#   type    = map(any)
#   default = {}
# }
#
# variable "query_service" {
#   type    = map(any)
#   default = {}
# }
#
# variable "default_service_secrets" {
#   type    = map(any)
#   default = {}
# }
#
# variable "global" {
#   type    = map(any)
#   default = {}
# }

variable "secrets" {
  type    = map(any)
  default = {}
}

variable "tags" {
  type    = map(any)
  default = {}
}

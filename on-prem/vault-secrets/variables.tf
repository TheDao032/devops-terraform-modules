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

variable "k3s_vms" {
  type    = map(any)
  default = {}
}

variable "k3s_envs" {
  type    = map(any)
  default = {}
}

variable "psql_vms" {
  type    = map(any)
  default = {}
}

variable "vault_vms" {
  type    = map(any)
  default = {}
}

variable "tags" {
  type    = map(any)
  default = {}
}

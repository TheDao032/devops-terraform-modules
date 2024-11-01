variable "environment" {
  type = string
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

variable "k3s_params" {
  type    = map(any)
  default = {}
}

variable "k3s_params_path" {
  description = "k3s env path"
  type    = string
  default = "k3s/params"
}

variable "k3s_secrets_path" {
  description = "k3s secrets path"
  type    = string
  default = "k3s/creds"
}

variable "jenkins_crds_path" {
  description = "jenkins secrets path"
  type    = string
  default = "jenkins/creds"
}

variable "grafana_crds_path" {
  description = "grafana secrets path"
  type    = string
  default = "grafana/creds"
}

variable "kafka_crds_path" {
  description = "kafka secrets path"
  type    = string
  default = "kafka/creds"
}

variable "vault_params" {
  type    = map(any)
  default = {}
}

variable "vault_secrets" {
  type    = map(any)
  default = {}
}

variable "vault_params_path" {
  description = "k3s env path"
  type    = string
  default = "vault/params"
}

variable "vault_secrets_path" {
  description = "k3s secrets path"
  type    = string
  default = "vault/creds"
}
variable "tags" {
  type    = map(any)
  default = {}
}

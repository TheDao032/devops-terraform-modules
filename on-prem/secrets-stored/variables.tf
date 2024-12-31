variable "environment" {
  type = string
}

variable "namespace" {
  description = "Vault namespace"
  type        = string
  default     = "default"
}

variable "vault_mount_path" {
  description = "Vault Mount Path"
  type        = string
}

variable "parameters" {
  type    = map(any)
  default = {}
}

variable "tags" {
  type    = map(any)
  default = {}
}

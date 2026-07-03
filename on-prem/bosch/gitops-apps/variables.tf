variable "environment" {
  type = string
}

variable "pod_restart_collector" {
  description = "Configuration for pod restart collector application"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags"
  type        = map(any)
  default     = {}
}

variable "host" {
  type = string
}

variable "client_key" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "token" {
  type = string
}

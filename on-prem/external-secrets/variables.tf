variable "environment" {
  type = string
}

variable "local" {
  description = "Configuration for local namespace values"
  type        = map(any)
  default     = {}
}

variable "gitops" {
  description = "Configuration for gitops namespace values"
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

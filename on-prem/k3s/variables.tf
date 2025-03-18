variable "environment" {
  type = string
}

variable "jenkins_conf" {
  description = "Configuration for Jenkins values"
  type        = map(any)
  default     = {}
}

variable "argocd_conf" {
  description = "Configuration for ArgoCD values"
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

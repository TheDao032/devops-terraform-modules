variable "environment" {
  type = string
}

variable "jenkins_conf" {
  description = "Configuration for Jenkins values"
  type        = map(any)
  default     = {}
}

variable "reloader_conf" {
  description = "Configuration for Jenkins values"
  type        = map(any)
  default     = {}
}

variable "argocd_conf" {
  description = "Configuration for ArgoCD values"
  type        = map(any)
  default     = {}
}

variable "argocd_img_upd_conf" {
  description = "Configuration for ArgoCD Img Updater values"
  type        = map(any)
  default     = {}
}

variable "coredns_conf" {
  description = "Configuration for CoreDNS values"
  type        = map(any)
  default     = {}
}

variable "kafka_conf" {
  description = "Configuration for Kafka values"
  type        = map(any)
  default     = {}
}

variable "consul_conf" {
  description = "Configuration for Consul values"
  type        = map(any)
  default     = {}
}

variable "vault_conf" {
  description = "Configuration for Consul values"
  type        = map(any)
  default     = {}
}

variable "external_secrets_conf" {
  description = "Configuration for Consul values"
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

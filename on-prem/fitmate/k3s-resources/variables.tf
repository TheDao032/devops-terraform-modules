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
  type        = any
  default     = {}
}

variable "argocd_img_upd_conf" {
  description = "Configuration for ArgoCD Img Updater values"
  type        = any
  default     = {}
}

variable "coredns_conf" {
  description = "Configuration for CoreDNS values"
  type        = any
  default     = {}
}

variable "kafka_conf" {
  description = "Configuration for Kafka values"
  type        = any
  default     = {}
}

variable "consul_conf" {
  description = "Configuration for Consul values"
  type        = any
  default     = {}
}

variable "vault_conf" {
  description = "Vault config incl. its own `routing` block (HTTPRoutes + BackendTLSPolicy)"
  type        = any
  default     = {}
}

variable "external_secrets_conf" {
  description = "Configuration for Consul values"
  type        = any
  default     = {}
}

variable "cert_manager_conf" {
  description = "Configuration for cert-manager (controller + CRDs; self-signed issuers)"
  type        = any
  default     = {}
}

variable "traefik_conf" {
  description = "Self-managed Traefik v3 controller (Helm) + its own `routing` block (dashboard IngressRoute)"
  type        = any
  default     = {}
}

variable "route_type" {
  description = "Routing controller for Gateway API routes: traefik | nginx (selects templates in shared/routing)"
  type        = string
  default     = "traefik"
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

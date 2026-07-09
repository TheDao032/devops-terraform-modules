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

variable "cert_manager_conf" {
  description = "Configuration for cert-manager (controller + CRDs; self-signed issuers)"
  type        = map(any)
  default     = {}
}

variable "traefik_crds_conf" {
  description = "Configuration for the traefik-crds chart (Traefik + Gateway API CRDs)"
  type        = map(any)
  default     = {}
}

variable "traefik_conf" {
  description = "Configuration for the self-managed Traefik v3 controller"
  type        = map(any)
  default     = {}
}

variable "routing_conf" {
  description = "Gateway API routes (HTTPRoutes + BackendTLSPolicy) for the Traefik v3 gateway"
  type        = any
  default     = {}
}

variable "nginx_conf" {
  description = "NGINX Gateway Fabric — alternative Gateway API data plane (see commented module)"
  type        = any
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

variable "environment" {
  description = "Environment name — threaded into every child Helm/routing/crds module."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "jenkins_conf" {
  # intentionally any: freeform Helm values / config block passed opaquely to a child module.
  description = "Configuration for Jenkins values (Helm release + config blocks)."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.jenkins_conf))
    error_message = "jenkins_conf must be a map/object."
  }
}

variable "reloader_conf" {
  # intentionally any: freeform Helm values / config block passed opaquely to the reloader module.
  description = "Configuration for the Stakater Reloader Helm release (helm + common blocks)."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.reloader_conf))
    error_message = "reloader_conf must be a map/object."
  }
}

variable "argocd_conf" {
  # intentionally any: heterogeneous ArgoCD config (helm/ingress/secret/github/common/routing),
  # sliced by try() in addons.tf and handed to child modules as opaque parameters.
  description = "Configuration for ArgoCD (helm/ingress/secret/github/common/routing blocks)."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.argocd_conf))
    error_message = "argocd_conf must be a map/object."
  }
}

variable "argocd_img_upd_conf" {
  # intentionally any: freeform ArgoCD Image Updater config passed opaquely to a child module.
  description = "Configuration for ArgoCD Image Updater values."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.argocd_img_upd_conf))
    error_message = "argocd_img_upd_conf must be a map/object."
  }
}

variable "coredns_conf" {
  # intentionally any: freeform CoreDNS Helm values (module currently commented out).
  description = "Configuration for CoreDNS values."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.coredns_conf))
    error_message = "coredns_conf must be a map/object."
  }
}

variable "kafka_conf" {
  # intentionally any: freeform Kafka Helm values (module currently commented out).
  description = "Configuration for Kafka values."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.kafka_conf))
    error_message = "kafka_conf must be a map/object."
  }
}

variable "consul_conf" {
  # intentionally any: freeform Consul Helm values (module currently commented out).
  description = "Configuration for Consul values."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.consul_conf))
    error_message = "consul_conf must be a map/object."
  }
}

variable "vault_conf" {
  # intentionally any: heterogeneous Vault config (helm/server/ui/common + optional routing),
  # sliced by try() in addons.tf and passed to the Helm module as opaque parameters.
  description = "Vault config incl. its own `routing` block (HTTPRoutes + BackendTLSPolicy)."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.vault_conf))
    error_message = "vault_conf must be a map/object."
  }
}

variable "external_secrets_conf" {
  # intentionally any: freeform External Secrets Operator Helm values (helm + common blocks).
  description = "Configuration for External Secrets Operator values."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.external_secrets_conf))
    error_message = "external_secrets_conf must be a map/object."
  }
}

variable "cert_manager_conf" {
  # intentionally any: freeform cert-manager Helm values (helm + common blocks).
  description = "Configuration for cert-manager (controller + CRDs; self-signed issuers)."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.cert_manager_conf))
    error_message = "cert_manager_conf must be a map/object."
  }
}

variable "traefik_conf" {
  # intentionally any: heterogeneous Traefik config (helm/common + optional routing block),
  # sliced by try() in addons.tf and passed to child modules as opaque parameters.
  description = "Self-managed Traefik v3 controller (Helm) + its own `routing` block (dashboard IngressRoute)."
  type        = any
  default     = {}

  validation {
    condition     = can(keys(var.traefik_conf))
    error_message = "traefik_conf must be a map/object."
  }
}

variable "route_type" {
  description = "Routing controller for Gateway API routes: traefik | nginx (selects templates in shared/routing)."
  type        = string
  default     = "traefik"

  validation {
    condition     = contains(["traefik", "nginx"], var.route_type)
    error_message = "route_type must be one of: traefik, nginx."
  }
}

variable "tags" {
  description = "Resource tags applied where the provider supports them."
  type        = map(string)
  default     = {}
}

variable "host" {
  description = "Kubernetes API server URL for the provider."
  type        = string

  validation {
    condition     = length(trimspace(var.host)) > 0
    error_message = "host must be a non-empty Kubernetes API server URL."
  }
}

variable "client_key" {
  description = "PEM-encoded client key for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "PEM-encoded client certificate for Kubernetes API authentication."
  type        = string
}

variable "cluster_ca_certificate" {
  description = "PEM-encoded cluster CA certificate for verifying the Kubernetes API server."
  type        = string
}

variable "token" {
  description = "Bearer token for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

variable "coredns_custom_conf" {
  # intentionally any: freeform { rewrites = [{ from, to }] }
  description = "Split-horizon DNS rewrites rendered into the k3s coredns-custom ConfigMap."
  type        = any
  default     = {}

  validation {
    condition = !can(var.coredns_custom_conf.rewrites) ? true : alltrue([
      for r in var.coredns_custom_conf.rewrites :
      length(trimspace(tostring(r.from))) > 0 && length(trimspace(tostring(r.to))) > 0
    ])
    error_message = "coredns_custom_conf.rewrites[*] must set a non-empty from and to."
  }
}

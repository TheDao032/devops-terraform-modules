variable "environment" {
  description = "Environment name — passed through to every ../helm submodule invocation."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

# NOTE on the *_conf variables below:
# Each is destructured in addons.tf as var.<x>.helm / .common / .secret / ... and the resulting
# sub-maps are forwarded verbatim into the ../helm submodule's `parameters`, which renders them
# into Helm values / templatefile. The sub-blocks are heterogeneous per chart (freeform
# `common = {}`, chart-specific keys, secrets), so the *values* are intentionally `any`. We only
# pin the top level to a map and light-guard the `helm` release descriptor that every chart needs.

variable "jenkins_conf" {
  description = "Configuration for the Jenkins Helm release (helm/secrets/common/plugins sub-maps). intentionally any: per-chart heterogeneous Helm values."
  type        = map(any)
  default     = {}

  validation {
    condition     = can(keys(var.jenkins_conf))
    error_message = "jenkins_conf must be a map of configuration sub-blocks."
  }
}

variable "reloader_conf" {
  description = "Configuration for the Stakater Reloader Helm release (helm/common sub-maps). intentionally any: per-chart heterogeneous Helm values."
  type        = map(any)
  default     = {}

  validation {
    condition     = can(keys(var.reloader_conf))
    error_message = "reloader_conf must be a map of configuration sub-blocks."
  }
}

variable "argocd_conf" {
  description = "Configuration for the ArgoCD Helm release (helm/ingress/secret/github/common sub-maps). intentionally any: per-chart heterogeneous Helm values + secrets."
  type        = map(any)
  default     = {}

  validation {
    condition     = can(keys(var.argocd_conf))
    error_message = "argocd_conf must be a map of configuration sub-blocks."
  }
}

variable "argocd_img_upd_conf" {
  description = "Configuration for the ArgoCD Image Updater Helm release (helm/docker/common sub-maps). intentionally any: per-chart heterogeneous Helm values."
  type        = map(any)
  default     = {}

  validation {
    condition     = can(keys(var.argocd_img_upd_conf))
    error_message = "argocd_img_upd_conf must be a map of configuration sub-blocks."
  }
}

variable "coredns_conf" {
  description = "Configuration for the CoreDNS Helm release (helm/common sub-maps). intentionally any: per-chart heterogeneous Helm values."
  type        = map(any)
  default     = {}

  validation {
    condition     = can(keys(var.coredns_conf))
    error_message = "coredns_conf must be a map of configuration sub-blocks."
  }
}

variable "kafka_conf" {
  description = "Configuration for the Kafka Helm release (helm/controller/broker/sasl/common sub-maps). intentionally any: per-chart heterogeneous Helm values + secrets."
  type        = map(any)
  default     = {}

  validation {
    condition     = can(keys(var.kafka_conf))
    error_message = "kafka_conf must be a map of configuration sub-blocks."
  }
}

variable "consul_conf" {
  description = "Configuration for the Consul Helm release (helm/server/common sub-maps). intentionally any: per-chart heterogeneous Helm values."
  type        = map(any)
  default     = {}

  validation {
    condition     = can(keys(var.consul_conf))
    error_message = "consul_conf must be a map of configuration sub-blocks."
  }
}

variable "vault_conf" {
  description = "Configuration for the Vault Helm release (helm/server/injector/ui/common sub-maps). intentionally any: per-chart heterogeneous Helm values + secrets."
  type        = map(any)
  default     = {}

  validation {
    condition     = can(keys(var.vault_conf))
    error_message = "vault_conf must be a map of configuration sub-blocks."
  }
}

variable "external_secrets_conf" {
  description = "Configuration for the External Secrets Helm release (helm/secret/common sub-maps). intentionally any: per-chart heterogeneous Helm values + secrets."
  type        = map(any)
  default     = {}

  validation {
    condition     = can(keys(var.external_secrets_conf))
    error_message = "external_secrets_conf must be a map of configuration sub-blocks."
  }
}

variable "tags" {
  description = "Resource tags passed through to the ../helm submodules."
  type        = map(string)
  default     = {}
}

variable "host" {
  description = "Kubernetes API server URL for the target cluster."
  type        = string

  validation {
    condition     = can(regex("^https?://", var.host))
    error_message = "host must be an http(s):// URL for the Kubernetes API server."
  }
}

variable "client_key" {
  description = "Base64-encoded client private key for Kubernetes API auth."
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "Base64-encoded client certificate for Kubernetes API auth."
  type        = string
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate for the Kubernetes API server."
  type        = string
  sensitive   = true
}

variable "token" {
  description = "Bearer token for Kubernetes API auth."
  type        = string
  sensitive   = true
}

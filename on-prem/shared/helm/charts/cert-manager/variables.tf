variable "chart_version" {
  type = string
}

variable "namespace" {
  type    = string
  default = "cert-manager"
}

variable "helm_release_name" {
  description = "Prometheus's helm release name"
  type        = string
  default     = ""
}

variable "helm_release_chart" {
  description = "Prometheus's helm release chart name"
  type        = string
  default     = ""
}

variable "helm_repository" {
  description = "Prometheus's helm repository"
  type        = string
  default     = ""
}

variable "email" {
  description = "Letencrypt email register"
  type        = string
  default     = ""
}

variable "cloudflare_secret_name" {
  description = "Cloudflare api secret name"
  type        = string
  default     = "cloudflare-api-token-secret"
}

# ACME/Cloudflare resources are temporarily disabled in main.tf. Default "" keeps this
# optional so units don't have to supply a token while ACME is off.
variable "cloudflare_api_token" {
  description = "Cloudflare api secret token"
  type        = string
  default     = ""
}

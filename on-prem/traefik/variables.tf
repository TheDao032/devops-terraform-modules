variable "chart_version" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "helm_release_name" {
  description = "Prometheus's helm release name"
  type        = string
  default     = "default"
}

variable "helm_release_chart" {
  description = "Prometheus's helm release chart name"
  type        = string
  default     = "kube-prometheus-stack"
}

variable "helm_repository" {
  description = "Prometheus's helm repository"
  type        = string
  default     = "https://prometheus-community.github.io/helm-charts"
}

variable "traefik_dashboard_ingress_route_name" {
  description = "Traefik dashboard"
  type        = string
  default     = "traefik-dashboard"
}

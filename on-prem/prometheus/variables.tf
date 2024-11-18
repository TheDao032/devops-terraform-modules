variable "environment" {
  type    = string
}

variable "chart_version" {
  type    = string
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "helm_release_name" {
  description = "Prometheus's helm release name"
  type    = string
  default = "prometheus"
}

variable "helm_release_chart" {
  description = "Prometheus's helm release chart name"
  type    = string
  default = "kube-prometheus-stack"
}

variable "helm_repository" {
  description = "Prometheus's helm repository"
  type    = string
  default = "https://prometheus-community.github.io/helm-charts"
}

variable "prometheus" {
  description = "Prometheus Ingress Data"
  type        = map(any)
  default     = {}
}

variable "alertmanager" {
  description = "Alertmanager Ingress Data"
  type        = map(any)
  default     = {}
}

variable "grafana" {
  description = "Grafana Ingress Data"
  type        = map(any)
  default     = {}
}

variable "external_server_ip" {
  description = "External server ip"
  type    = string
}

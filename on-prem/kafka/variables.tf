variable "chart_version" {
  type    = string
}

variable "prometheus_ingress" {
  description = "Prometheus Ingress Data"
  type        = map(any)
  default     = {}
}

variable "alertmanager_ingress" {
  description = "Alertmanager Ingress Data"
  type        = map(any)
  default     = {}
}

variable "grafana_ingress" {
  description = "Grafana Ingress Data"
  type        = map(any)
  default     = {}
}

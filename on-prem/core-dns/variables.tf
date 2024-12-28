variable "namespace" {
  description = "Kafka's namespace"
  type        = string
  default     = "default"
}

variable "helm_repository" {
  description = "Repository of Kafka"
  type        = string
  default     = "https://charts.bitnami.com/bitnami"
}


variable "helm_release_name" {
  description = "Kafka's helm release name"
  type        = string
  default     = "kafka"
}

variable "helm_release_chart" {
  description = "Kafka's helm release chart name"
  type        = string
  default     = "kafka"
}

variable "chart_version" {
  description = "Loki's Helm Chart Version"
  type        = string
  default     = "30.1.5"
}

variable "coredns_conf" {
  description = "alloy Conf Data"
  type        = map(any)
  default     = {}
}

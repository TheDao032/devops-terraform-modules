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


variable "loki_helm_release_name" {
  description = "Kafka's helm release name"
  type        = string
  default     = "kafka"
}

variable "loki_helm_release_chart" {
  description = "Kafka's helm release chart name"
  type        = string
  default     = "kafka"
}

variable "loki_chart_version" {
  description = "Loki's Helm Chart Version"
  type        = string
  default     = "30.1.5"
}

variable "alloy_helm_release_name" {
  description = "Alloy's helm release name"
  type        = string
  default     = "kafka"
}

variable "alloy_helm_release_chart" {
  description = "Kafka's helm release chart name"
  type        = string
  default     = "kafka"
}

variable "alloy_chart_version" {
  description = "Helm Chart Version"
  type        = string
  default     = "30.1.5"
}

variable "common_conf" {
  description = "Loki Conf Data"
  type        = map(any)
  default     = {}
}

variable "microservice_conf" {
  description = "Loki Conf Data"
  type        = map(any)
  default     = {}
}

variable "monolithic_conf" {
  description = "Loki Conf Data"
  type        = map(any)
  default     = {}
}

variable "scalable_conf" {
  description = "Loki Conf Data"
  type        = map(any)
  default     = {}
}

variable "auth_conf" {
  description = "alloy Conf Data"
  type        = map(any)
  default     = {}
}

variable "alloy_conf" {
  description = "alloy Conf Data"
  type        = map(any)
  default     = {}
}

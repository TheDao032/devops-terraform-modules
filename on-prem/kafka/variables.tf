variable "chart_version" {
  description = "Helm Chart Version"
  type    = string
  default = "30.1.5"
}

variable "image_tag" {
  description = "Kafka's Docker image tag version"
  type = string
  default = "3.8.0-debian-12-r6"
}

variable "namespace" {
  description = "Kafka's namespace"
  type    = string
  default = "default"
}

variable "helm_release_name" {
  description = "Kafka's helm release name"
  type    = string
  default = "bitnami"
}

variable "helm_release_chart" {
  description = "Kafka's helm release chart name"
  type    = string
  default = "kafka"
}

variable "helm_repository" {
  description = "Repository of Kafka"
  type    = string
  default = "https://charts.bitnami.com/bitnami"
}

variable "controller_conf" {
  description = "Controller Conf Data"
  type        = map(any)
  default     = {}
}

variable "broker_conf" {
  description = "Broker Conf Data"
  type        = map(any)
  default     = {}
}

variable "sasl_conf" {
  description = "Broker Conf Data"
  type        = map(any)
  default     = {}
}

variable "chart_version" {
  description = "Helm Chart Version"
  type        = string
}

variable "image_tag" {
  description = "Kafka's Docker image tag version"
  type        = string
}

variable "namespace" {
  description = "KafkaUI's namespace"
  type        = string
}

variable "helm_release_name" {
  description = "KafkaUI's helm release name"
  type        = string
  default     = "kafka-ui"
}

variable "helm_release_chart" {
  description = "KafkaUI's helm release chart name"
  type        = string
  default     = "kafka-ui"
}

variable "helm_repository" {
  description = "Repository of KafkaUI"
  type        = string
  default     = "https://provectus.github.io/kafka-ui-charts"
}

variable "kafka_ui_host" {
  description = "Repository of Kafka"
  type        = string
}

variable "kafka_ui_conf" {
  description = "Kafka UI Conf Data"
  type        = map(any)
  default     = {}
}

variable "keycloak" {
  description = "KeyCloak Configuration"
  type        = map(any)
  default     = {}
}

variable "keycloak_kafka_ui_credentials" {
  description = "KeyCloak Kafka UI Credentials"
  type        = map(any)
  default     = {}
}

variable "internal_bootstrap_server" {
  description = "Internal Bootstrap Server"
  type        = string
}

variable "internal_bootstrap_server_port" {
  description = "Internal Bootstrap Server"
  type        = number
}

variable "environment" {
  description = "Environment"
  type        = string
}

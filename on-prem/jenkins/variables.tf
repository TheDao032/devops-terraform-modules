variable "chart_version" {
  description = "Helm Chart Version"
  type    = string
  default = "5.7.3"
}

variable "image_tag" {
  description = "Jenkins's Docker image tag version"
  type    = string
  default = "2.479-jdk17"
}

variable "namespace" {
  description = "Jenkins's namespace"
  type    = string
  default = "ci-cd"
}

variable "helm_repository" {
  description = "Repository of Jenkins"
  type    = string
  default = "https://charts.jenkins.io/"
}

variable "helm_release_name" {
  description = "Jenkins's helm release name"
  type    = string
  default = "bitnami"
}

variable "helm_release_chart" {
  description = "Jenkins's helm release chart name"
  type    = string
  default = "kafka"
}

variable "parameters" {
  description = "Parameters list for Jenkins values"
  type        = map(any)
  default     = {}
}

variable "jenkins_plugins" {
  description = "Plugins list for Jenkins values"
  type = map(any)
  default = {}
}

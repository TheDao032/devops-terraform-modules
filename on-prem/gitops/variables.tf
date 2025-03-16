variable "environment" {
  type = string
}

variable "jenkins_conf" {
  description = "Plugins list for Jenkins values"
  type = map(any)
  default = {}
}

variable "argocd_conf" {
  description = "Plugins list for Jenkins values"
  type = map(any)
  default = {}
}

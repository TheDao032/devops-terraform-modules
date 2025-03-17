variable "environment" {
  type = string
}

variable "jenkins_conf" {
  description = "Configuration for Jenkins values"
  type = map(any)
  default = {}
}

variable "argocd_conf" {
  description = "Configuration for ArgoCD values"
  type = map(any)
  default = {}
}

variable "tags" {
  description = "Tags"
  type = map(any)
  default = {}
}

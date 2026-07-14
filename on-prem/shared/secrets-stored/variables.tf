variable "environment" {
  type = string
}

variable "namespace" {
  type = string
}

variable "enabled" {
  type    = number
  default = 1
}

variable "disabled" {
  type    = number
  default = 0
}

# variable "name" {
#   type = string
# }

variable "parameters" {
  description = "Chart's parameters"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags"
  type        = map(any)
  default     = {}
}

variable "host" {
  type = string
}

variable "client_key" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "token" {
  type = string
}

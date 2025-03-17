variable "environment" {
  type = string
}

variable "enabled" {
  type    = number
  default = 1
}

variable "chart" {
  type = string
}

variable "namespace" {
  type = string
}

variable "name" {
  type = string
}

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

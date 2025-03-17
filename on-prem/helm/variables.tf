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

variable "chart" {
  type    = string
  default = null
}

variable "name" {
  type = string
}

variable "repository" {
  type = string
}

variable "release_name" {
  type = string
}

variable "chart_version" {
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

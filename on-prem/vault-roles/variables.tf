variable "environment" {
  type = string
}

variable "roles" {
  description = "Policy list"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags"
  type        = map(any)
  default     = {}
}

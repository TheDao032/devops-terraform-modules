variable "rbacs" {
  description = "Service Accounts list map"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags"
  type        = map(any)
  default     = {}
}

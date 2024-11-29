variable "azs" {
  type = list(any)
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "subnet_id" {
  type = string
}

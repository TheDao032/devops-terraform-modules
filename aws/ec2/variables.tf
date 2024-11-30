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

variable "private_subnet_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

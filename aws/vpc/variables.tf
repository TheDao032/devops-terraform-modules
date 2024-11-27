variable "environment" {
  type = string
}

variable "export_name" {
  type    = string
  default = "vpc"
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_cidr" {
  type = list(any)
}

variable "public_cidr" {
  type = list(any)
}

variable "azs" {
  type = list(any)
}

variable "tags" {
  type    = map(any)
  default = {}
}

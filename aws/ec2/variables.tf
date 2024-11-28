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

variable "ec2_instances" {
  type    = list(any)
  default = []
}

variable "ec2_subnet_id" {
  type = string
}

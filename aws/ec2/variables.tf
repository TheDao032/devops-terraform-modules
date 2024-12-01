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

variable "key_pair" {
  type    = string
  default = "k3s_cluster"
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "private_sg_id" {
  type = string
}

variable "public_sg_id" {
  type = string
}

variable "associate_public_ip_address" {
  type    = bool
  default = true
}

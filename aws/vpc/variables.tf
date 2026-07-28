variable "environment" {
  description = "Environment name — used as the VPC/subnet/SG Name tag prefix."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "export_name" {
  description = "Logical export name for the VPC (used by consumers referencing this stack)."
  type        = string
  default     = "vpc"

  validation {
    condition     = length(trimspace(var.export_name)) > 0
    error_message = "export_name must be a non-empty string."
  }
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be a valid IPv4 CIDR block (e.g. \"10.0.0.0/16\")."
  }
}

variable "private_cidr" {
  description = "List of private subnet CIDR blocks (one subnet per entry)."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.private_cidr : can(cidrhost(c, 0))])
    error_message = "every private_cidr entry must be a valid IPv4 CIDR block."
  }
}

variable "public_cidr" {
  description = "List of public subnet CIDR blocks (one subnet per entry). Also drives NAT/EIP/route counts."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.public_cidr : can(cidrhost(c, 0))])
    error_message = "every public_cidr entry must be a valid IPv4 CIDR block."
  }
}

variable "azs" {
  description = "Availability zones the subnets are placed in (sorted before use)."
  type        = list(string)

  validation {
    condition     = length(var.azs) > 0
    error_message = "azs must contain at least one availability zone."
  }

  validation {
    condition     = alltrue([for az in var.azs : can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", az))])
    error_message = "each az must look like an AWS availability zone (e.g. \"us-west-2a\")."
  }
}

variable "map_public_ip_on_launch" {
  description = "Whether public subnets auto-assign a public IP on instance launch."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags merged onto every VPC resource."
  type        = map(string)
  default     = {}
}

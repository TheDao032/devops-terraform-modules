variable "azs" {
  description = "Availability zones to spread instances across (sorted before use)."
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

variable "environment" {
  description = "Environment name — used in the Name tag of every instance."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "tags" {
  description = "Resource tags merged onto each instance."
  type        = map(string)
  default     = {}
}

variable "private_subnet_id" {
  description = "Subnet ID for private instances."
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]+$", var.private_subnet_id))
    error_message = "private_subnet_id must be a valid subnet ID (subnet-...)."
  }
}

variable "public_subnet_id" {
  description = "Subnet ID for the public instance."
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]+$", var.public_subnet_id))
    error_message = "public_subnet_id must be a valid subnet ID (subnet-...)."
  }
}

variable "key_pair" {
  description = "Name of the EC2 key pair to attach for SSH access."
  type        = string
  default     = "k3s_cluster"

  validation {
    condition     = length(trimspace(var.key_pair)) > 0
    error_message = "key_pair must be a non-empty key pair name."
  }
}

variable "ssh_public_key" {
  description = "SSH public key material registered as the key pair (may be empty to reuse an existing key)."
  type        = string
  default     = ""
}

variable "private_sg_id" {
  description = "Security group ID for private instances."
  type        = string

  validation {
    condition     = can(regex("^sg-[0-9a-f]+$", var.private_sg_id))
    error_message = "private_sg_id must be a valid security group ID (sg-...)."
  }
}

variable "public_sg_id" {
  description = "Security group ID for the public instance."
  type        = string

  validation {
    condition     = can(regex("^sg-[0-9a-f]+$", var.public_sg_id))
    error_message = "public_sg_id must be a valid security group ID (sg-...)."
  }
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP with the public instance."
  type        = bool
  default     = true
}

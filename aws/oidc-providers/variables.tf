variable "github_org" {
  description = "GitHub organization name (used to build the OIDC subject claim)."
  type        = string

  validation {
    condition     = length(trimspace(var.github_org)) > 0
    error_message = "github_org must be a non-empty GitHub organization name."
  }
}

variable "github_repo" {
  description = "GitHub repository name (used to build the OIDC subject claim)."
  type        = string

  validation {
    condition     = length(trimspace(var.github_repo)) > 0
    error_message = "github_repo must be a non-empty GitHub repository name."
  }
}

# variable "github_branches" {
#   description = "List of GitHub branches allowed to assume the role"
#   type        = list(string)
#   default     = ["main", "master"]
# }

# variable "environment" {
#   description = "Environment name (e.g., dev, staging, prod)"
#   type        = string
#   default     = "dev"
# }

# variable "project_name" {
#   description = "Project name for resource naming"
#   type        = string
# }

# variable "aws_region" {
#   description = "AWS region"
#   type        = string
#   default     = "us-west-2"
# }

variable "allowed_instance_types" {
  description = "List of allowed EC2 instance types (referenced by the runner IAM policy conditions)."
  type        = list(string)
  default     = ["t3.micro", "t3.small", "t3.medium"]

  validation {
    condition     = length(var.allowed_instance_types) > 0
    error_message = "allowed_instance_types must list at least one instance type."
  }

  validation {
    condition     = alltrue([for t in var.allowed_instance_types : can(regex("^[a-z0-9]+\\.[a-z0-9]+$", t))])
    error_message = "each allowed_instance_types entry must look like an EC2 instance type (e.g. \"t3.micro\")."
  }
}

variable "enable_spot_instances" {
  description = "Whether to allow Spot instance creation via the runner IAM policy."
  type        = bool
  default     = false
}

variable "github_personal_access_token_secret_name" {
  description = "Name of the GitHub PAT secret in AWS Secrets Manager (a reference, not the secret value; optional)."
  type        = string
  default     = ""
}

variable "thumbprint" {
  description = "OIDC provider TLS thumbprint list (SHA-1 fingerprints of the intermediate CA certs)."
  type        = list(string)
  default = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "d89e3bd43d5d909b47a18977aa9d5ce36cee184c"
  ]

  validation {
    condition     = length(var.thumbprint) > 0
    error_message = "thumbprint must contain at least one certificate fingerprint."
  }

  validation {
    condition     = alltrue([for t in var.thumbprint : can(regex("^[0-9a-fA-F]{40}$", t))])
    error_message = "each thumbprint must be a 40-character hex SHA-1 fingerprint."
  }
}

variable "github_oidc_url" {
  description = "OIDC provider issuer URL for GitHub Actions."
  type        = string
  default     = "https://token.actions.githubusercontent.com"

  validation {
    condition     = can(regex("^https://", var.github_oidc_url))
    error_message = "github_oidc_url must be an https:// URL."
  }
}

variable "tags" {
  description = "Resource tags applied to the OIDC provider and IAM resources."
  type        = map(string)
  default     = {}
}

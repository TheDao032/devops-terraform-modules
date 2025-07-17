variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
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
  description = "List of allowed EC2 instance types"
  type        = list(string)
  default     = ["t3.micro", "t3.small", "t3.medium"]
}

variable "enable_spot_instances" {
  description = "Whether to allow Spot instance creation"
  type        = bool
  default     = false
}

variable "github_personal_access_token_secret_name" {
  description = "Name of the GitHub PAT secret in AWS Secrets Manager (optional)"
  type        = string
  default     = ""
}

variable "thumbprint" {
  description = "List of allowed EC2 instance types"
  type        = list(string)
  default     = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "d89e3bd43d5d909b47a18977aa9d5ce36cee184c"
  ]

}

variable "github_oidc_url" {
  description = "Name of the GitHub PAT secret in AWS Secrets Manager (optional)"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "tags" {
  type    = map(any)
  default = {}
}


terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }

    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = "~> 2.25.0"
    # }
  }
}

provider "kubectl" {
  apply_retry_count = 1
  load_config_file  = false

  host                   = var.host
  client_key             = base64decode("${var.client_key}")
  client_certificate     = base64decode("${var.client_certificate}")
  cluster_ca_certificate = base64decode("${var.cluster_ca_certificate}")
  token                  = var.token
}

# provider "kubernetes" {
#   host                   = var.host
#   client_key             = base64decode("${var.client_key}")
#   client_certificate     = base64decode("${var.client_certificate}")
#   cluster_ca_certificate = base64decode("${var.cluster_ca_certificate}")
#   token                  = var.token
# }

# provider "helm" {
#   kubernetes {
#     host                   = var.host
#     client_key             = base64decode("${var.client_key}")
#     client_certificate     = base64decode("${var.client_certificate}")
#     cluster_ca_certificate = base64decode("${var.cluster_ca_certificate}")
#     token                  = var.token
#   }
# }

locals {
  local_common = var.local.common
  local_secret = var.local.secret

  gitops_common = var.gitops.common
  gitops_secret = var.gitops.secret

  disabled = 0
  enabled  = 1
}

module "local-secrets-store" {
  source                 = "../secrets-stored"
  enabled                = local.enabled
  environment            = var.environment
  org                    = var.org
  namespace              = local.local_common.namespace
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags

  parameters = {
    common = local.local_common
    secret = local.local_secret
  }
}

module "gitops-secrets-store" {
  source                 = "../secrets-stored"
  enabled                = local.enabled
  environment            = var.environment
  org                    = var.org
  namespace              = local.gitops_common.namespace
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags

  parameters = {
    common = local.gitops_common
    secret = local.gitops_secret
  }
}

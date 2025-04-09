locals {
  pod_res_col_docker = var.pod_restart_collector.docker
  pod_res_col_github = var.pod_restart_collector.github
  pod_res_col_common = var.pod_restart_collector.common
  pod_res_col_argocd = var.pod_restart_collector.argocd
  pod_res_col_secret = var.pod_restart_collector.secret

  disabled = 0
  enabled  = 1
}

module "pod-restart-collector" {
  source                 = "../gitops"
  enabled                = local.disabled
  environment            = var.environment
  name                   = local.pod_res_col_common.app_name
  namespace              = local.pod_res_col_common.namespace
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common = local.pod_res_col_common
    secret = local.pod_res_col_secret
    argocd = local.pod_res_col_argocd
    docker = local.pod_res_col_docker
    github = local.pod_res_col_github
  }
}

locals {
  argocd_helm     = var.argocd_conf.helm
  argocd_values   = var.argocd_conf.values
  jenkins_helm    = var.jenkins_conf.helm
  jenkins_values  = var.jenkins_conf.values
  jenkins_plugins = var.jenkins_conf.plugins
}

module "argocd" {
  source        = "../helm"
  enabled       = 1
  environment   = var.environment
  name          = local.argocd_helm.release_name
  namespace     = local.argocd_helm.namespace
  repository    = local.argocd_helm.repository
  chart_version = local.argocd_helm.chart_version
  tags          = var.tags
  parameters = {
    values = local.argocd_values
  }
}

module "jenkins" {
  source        = "../helm"
  enabled       = 0
  environment   = var.environment
  name          = var.jenkins_helm.release_name
  namespace     = var.jenkins_helm.namespace
  repository    = var.jenkins_helm.repository
  chart_version = var.jenkins_helm.chart_version
  tags          = var.tags
  parameters = {
    values  = local.jenkins_values
    plugins = local.jenkins_plugins
  }
}

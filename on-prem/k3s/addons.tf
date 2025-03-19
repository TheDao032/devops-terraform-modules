locals {
  argocd_helm   = var.argocd_conf.helm
  argocd_values = var.argocd_conf.values

  jenkins_helm    = var.jenkins_conf.helm
  jenkins_values  = var.jenkins_conf.values
  jenkins_plugins = var.jenkins_conf.plugins

  argocd_middleware_strip_prefixes = [
    {
      name      = "argocd-strip-prefix"
      prefixes  = [local.argocd_values.baseref]
      namespace = "gitops"
    },
  ]

  # middleware_headers_list = [
  #   {
  #     name      = ""
  #     headers      = ["", ""]
  #     namespace = var.namespace
  #   },
  # ]

  argocd_middleware_combined = concat(
    local.argocd_middleware_strip_prefixes,
    # local.middleware_headers_list,
  )

  argocd_router = {
    middleware_strip_prefixes = local.argocd_middleware_strip_prefixes
    middleware_combined       = local.argocd_middleware_combined
    ingressroutes = [
      {
        ingress_route_name = "argocd-ingressroute"
        match_condition    = "PathPrefix(`${local.argocd_values.baseref}`)"
        namespace          = "gitops"
        services = [
          {
            name      = "argo-cd-argocd-server"
            port      = 80
            namespace = "gitops"
          }
        ]

        middleware_annotations = join(",", [for key, middleware in local.argocd_middleware_combined : "gitops-${middleware.name}@kubernetescrd"])
        middlewares = flatten([for key, middleware in local.argocd_middleware_combined : {
          name      = middleware.name
          namespace = middleware.namespace
        }])
      }
    ]
  }

}

module "argocd" {
  source                 = "../helm"
  enabled                = 1
  environment            = var.environment
  name                   = local.argocd_helm.release_name
  namespace              = local.argocd_helm.namespace
  repository             = local.argocd_helm.repository
  chart_version          = local.argocd_helm.chart_version
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    values = local.argocd_values
  }
}

module "argocd-router" {
  source                 = "../router"
  enabled                = 1
  environment            = var.environment
  namespace              = local.argocd_helm.namespace
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    router = local.argocd_router
  }
}

# module "jenkins" {
#   source                 = "../helm"
#   enabled                = 0
#   environment            = var.environment
#   name                   = local.jenkins_helm.release_name
#   namespace              = local.jenkins_helm.namespace
#   repository             = local.jenkins_helm.repository
#   chart_version          = local.jenkins_helm.chart_version
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     values  = local.jenkins_values
#     plugins = local.jenkins_plugins
#   }
# }

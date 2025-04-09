# terraform {
#   required_providers {
#     kubectl = {
#       source  = "alekc/kubectl"
#       version = "~> 2.1.3"
#
#     }
#   }
# }
#
# provider "kubectl" {
#   apply_retry_count = 1
#   load_config_file  = false
#
#   host                   = var.host
#   client_key             = base64decode("${var.client_key}")
#   client_certificate     = base64decode("${var.client_certificate}")
#   cluster_ca_certificate = base64decode("${var.cluster_ca_certificate}")
#   token                  = var.token
# }

locals {
  # argocd_middleware_strip_prefixes = [
  #   {
  #     name      = "argocd-strip-prefix"
  #     prefixes  = [local.argocd_ingress.midl_prefix]
  #     namespace = "gitops"
  #   },
  # ]
  #
  # # middleware_headers_list = [
  # #   {
  # #     name      = ""
  # #     headers      = ["", ""]
  # #     namespace = var.namespace
  # #   },
  # # ]
  #
  # argocd_middleware_combined = concat(
  #   local.argocd_middleware_strip_prefixes,
  #   # local.middleware_headers_list,
  # )
  #
  # argocd_router = {
  #   middleware_strip_prefixes = local.argocd_middleware_strip_prefixes
  #   middleware_combined       = local.argocd_middleware_combined
  #   ingressroutes = [
  #     {
  #       ingress_route_name = "argocd-ingressroute"
  #       match_condition    = "PathPrefix(`${local.argocd_ingress.ingroute_prefix}`)"
  #       namespace          = "gitops"
  #       services = [
  #         {
  #           name      = "argo-cd-argocd-server"
  #           port      = 80
  #           namespace = "gitops"
  #         }
  #       ]
  #
  #       middleware_annotations = join(",", [for key, middleware in local.argocd_middleware_combined : "gitops-${middleware.name}@kubernetescrd"])
  #       middlewares = flatten([for key, middleware in local.argocd_middleware_combined : {
  #         name      = middleware.name
  #         namespace = middleware.namespace
  #       }])
  #     }
  #   ]
  # }

  kafka_helm       = var.kafka_conf.helm
  kafka_controller = var.kafka_conf.controller
  kafka_broker     = var.kafka_conf.broker
  kafka_sasl       = var.kafka_conf.sasl

  consul_helm   = var.consul_conf.helm
  consul_server = var.consul_conf.server
  consul_common = var.consul_conf.common

  vault_helm     = var.vault_conf.helm
  vault_server   = var.vault_conf.server
  vault_injector = var.vault_conf.injector
  vault_ui       = var.vault_conf.ui
  vault_common   = var.vault_conf.common

  external_secrets_helm   = var.external_secrets_conf.helm
  external_secrets_common = var.external_secrets_conf.common
  external_secrets_secret = var.external_secrets_conf.secret

  coredns_helm   = var.coredns_conf.helm
  coredns_common = var.coredns_conf.common

  jenkins_helm    = var.jenkins_conf.helm
  jenkins_common  = var.jenkins_conf.common
  jenkins_secrets = var.jenkins_conf.secrets
  jenkins_plugins = var.jenkins_conf.plugins

  argocd_helm = var.argocd_conf.helm
  # argocd_docker  = var.argocd_conf.docker
  argocd_github  = var.argocd_conf.github
  argocd_common  = var.argocd_conf.common
  argocd_ingress = var.argocd_conf.ingress
  argocd_secret  = var.argocd_conf.secret

  argocd_img_upd_helm   = var.argocd_img_upd_conf.helm
  argocd_img_upd_docker = var.argocd_img_upd_conf.docker
  argocd_img_upd_common = var.argocd_img_upd_conf.common

  reloader_helm   = var.reloader_conf.helm
  reloader_common = var.reloader_conf.common

  disabled = 0
  enabled  = 1

  # argocd_img_upd_secret_store = var.argocd_img_upd_conf.secret_store
  # argocd_img_upd_github       = var.argocd_img_upd_conf.github

  # images_upd = [
  #   {
  #     name    = "k8s-pod-restart-info-collector"
  #     version = "latest"
  #   },
  #   {
  #     name    = "dumpuser-service"
  #     version = "latest"
  #   },
  # ]
}

module "external-secrets" {
  source                 = "../helm"
  enabled                = local.enabled
  environment            = var.environment
  name                   = local.external_secrets_helm.release_name
  namespace              = local.external_secrets_helm.namespace
  repository             = local.external_secrets_helm.repository
  chart_version          = local.external_secrets_helm.chart_version
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common = local.external_secrets_common
    secret = local.external_secrets_secret
  }
}

module "core-dns" {
  source                 = "../helm"
  enabled                = local.enabled
  environment            = var.environment
  name                   = local.coredns_helm.release_name
  namespace              = local.coredns_helm.namespace
  repository             = local.coredns_helm.repository
  chart_version          = local.coredns_helm.chart_version
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common = local.coredns_common
  }
}

module "reloader" {
  source                 = "../helm"
  enabled                = local.enabled
  environment            = var.environment
  name                   = local.reloader_helm.release_name
  namespace              = local.reloader_helm.namespace
  repository             = local.reloader_helm.repository
  chart_version          = local.reloader_helm.chart_version
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common = local.reloader_common
  }
}

# resource "null_resource" "ex_secrets_ready" {
#   depends_on = [module.external-secrets]
# }

module "argocd" {
  source                 = "../helm"
  enabled                = local.enabled
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
    common  = local.argocd_common
    ingress = local.argocd_ingress
    github  = local.argocd_github
    secret  = local.argocd_secret
  }

  # depends_on = [null_resource.ex_secrets_ready]
}

module "argocd-img-update" {
  source                 = "../helm"
  enabled                = local.enabled
  environment            = var.environment
  name                   = local.argocd_img_upd_helm.release_name
  namespace              = local.argocd_img_upd_helm.namespace
  repository             = local.argocd_img_upd_helm.repository
  chart_version          = local.argocd_img_upd_helm.chart_version
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common = merge(local.argocd_img_upd_common, {
      argocd_server_url = module.argocd.argocd_server_url
    })
    docker = local.argocd_img_upd_docker
    # docker = merge(
    #   local.argocd_img_upd_docker, {
    #     images = join(",",
    #     formatlist("${local.argocd_img_upd_docker.organization}/%s", [for img in local.images_upd : "${img.name}:${img.version}"]))
    #   }
    # )
    # github = local.argocd_img_upd_github

  }

  # depends_on = [null_resource.ex_secrets_ready]
}

module "jenkins" {
  source                 = "../helm"
  enabled                = local.enabled
  environment            = var.environment
  name                   = local.jenkins_helm.release_name
  namespace              = local.jenkins_helm.namespace
  repository             = local.jenkins_helm.repository
  chart_version          = local.jenkins_helm.chart_version
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    secrets = local.jenkins_secrets
    common  = local.jenkins_common
    plugins = local.jenkins_plugins
  }
}

# module "consul" {
#   source                 = "../helm"
#   enabled                = 1
#   environment            = var.environment
#   name                   = local.consul_helm.release_name
#   namespace              = local.consul_helm.namespace
#   repository             = local.consul_helm.repository
#   chart_version          = local.consul_helm.chart_version
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     server = local.consul_server
#     common = local.consul_common
#   }
# }

# module "vault" {
#   source                 = "../helm"
#   enabled                = 1
#   environment            = var.environment
#   name                   = local.vault_helm.release_name
#   namespace              = local.vault_helm.namespace
#   repository             = local.vault_helm.repository
#   chart_version          = local.vault_helm.chart_version
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     server   = local.vault_server
#     injector = local.vault_injector
#     ui       = local.vault_ui
#     common   = local.vault_common
#   }
# }

# module "kafka" {
#   source                 = "../helm"
#   enabled                = 0
#   environment            = var.environment
#   name                   = local.kafka_helm.release_name
#   namespace              = local.kafka_helm.namespace
#   repository             = local.kafka_helm.repository
#   chart_version          = local.kafka_helm.chart_version
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     values = local.kafka_values
#   }
# }

# module "argocd-router" {
#   source                 = "../router"
#   enabled                = 1
#   environment            = var.environment
#   namespace              = local.argocd_helm.namespace
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     router = local.argocd_router
#   }
# }

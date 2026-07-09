locals {
  # CoreDNS is managed by k3s itself (rancher/mirrored-coredns-coredns:1.11.3) since the lab
  # no longer passes --disable=coredns. The terraform core-dns module below is commented out
  # so it doesn't fight k3s for the kube-system coredns/kube-dns resources.
  # coredns_helm   = var.coredns_conf.helm
  # coredns_common = var.coredns_conf.common

  cert_manager_helm   = var.cert_manager_conf.helm
  cert_manager_common = var.cert_manager_conf.common

  # Self-managed Traefik v3 (bundled Traefik disabled via --disable=traefik). traefik-crds
  # installs the Traefik + Gateway API CRDs first; the traefik release then brings up the
  # controller + a default GatewayClass/Gateway.
  traefik_crds_helm   = var.traefik_crds_conf.helm
  traefik_crds_common = var.traefik_crds_conf.common

  traefik_helm   = var.traefik_conf.helm
  traefik_common = var.traefik_conf.common

  # Gateway API routes (HTTPRoute + BackendTLSPolicy) served by the self-managed Traefik v3.
  routing_route_type           = var.routing_conf.route_type
  routing_namespace            = var.routing_conf.namespace
  routing_httproutes           = var.routing_conf.httproutes
  routing_backend_tls_policies = var.routing_conf.backend_tls_policies
  routing_dashboard_routes     = var.routing_conf.dashboard_routes
  # gateways: empty for Traefik (its chart makes the Gateway); set for nginx/NGF.
  routing_gateways = try(var.routing_conf.gateways, [])

  vault_helm   = var.vault_conf.helm
  vault_server = var.vault_conf.server
  vault_ui     = var.vault_conf.ui
  vault_common = var.vault_conf.common

  external_secrets_helm   = var.external_secrets_conf.helm
  external_secrets_common = var.external_secrets_conf.common
  # external_secrets_secret = var.external_secrets_conf.secret

  # kafka_helm       = var.kafka_conf.helm
  # kafka_controller = var.kafka_conf.controller
  # kafka_broker     = var.kafka_conf.broker
  # kafka_sasl       = var.kafka_conf.sasl

  # argocd_helm = var.argocd_conf.helm
  # # argocd_docker  = var.argocd_conf.docker
  # argocd_github  = var.argocd_conf.github
  # argocd_common  = var.argocd_conf.common
  # argocd_ingress = var.argocd_conf.ingress
  # argocd_secret  = var.argocd_conf.secret
  #
  # argocd_img_upd_helm   = var.argocd_img_upd_conf.helm
  # argocd_img_upd_docker = var.argocd_img_upd_conf.docker
  # argocd_img_upd_common = var.argocd_img_upd_conf.common
  #
  # reloader_helm   = var.reloader_conf.helm
  # reloader_common = var.reloader_conf.common

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

# CoreDNS is managed by k3s (see note in locals). Disabled here to avoid a Helm-vs-k3s
# ownership conflict on the kube-system coredns/kube-dns resources.
/*
module "core-dns" {
  source                 = "../../shared/helm"
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
*/

module "cert-manager" {
  source                 = "../../shared/helm"
  enabled                = local.enabled
  environment            = var.environment
  name                   = local.cert_manager_helm.release_name
  namespace              = local.cert_manager_helm.namespace
  repository             = local.cert_manager_helm.repository
  chart_version          = local.cert_manager_helm.chart_version
  values_type            = local.cert_manager_helm.values_type
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common = local.cert_manager_common
  }
}

# Gateway API + Traefik CRDs. Must land BEFORE the traefik release so its Gateway/
# GatewayClass resources can render, and before any HTTPRoute/BackendTLSPolicy.
module "traefik-crds" {
  source                 = "../../shared/helm"
  enabled                = local.enabled
  environment            = var.environment
  name                   = local.traefik_crds_helm.release_name
  namespace              = local.traefik_crds_helm.namespace
  repository             = local.traefik_crds_helm.repository
  chart_version          = local.traefik_crds_helm.chart_version
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common = local.traefik_crds_common
  }
}

# Traefik v3 controller + default GatewayClass/Gateway (self-managed; replaces bundled v2.11).
module "traefik" {
  source                 = "../../shared/helm"
  enabled                = local.enabled
  environment            = var.environment
  name                   = local.traefik_helm.release_name
  namespace              = local.traefik_helm.namespace
  repository             = local.traefik_helm.repository
  chart_version          = local.traefik_helm.chart_version
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common = local.traefik_common
  }

  depends_on = [module.traefik-crds]
}

# ── ALTERNATIVE data plane: NGINX Gateway Fabric (Gateway API) ──────────────────
# Ready-but-inactive. Traefik is the active controller; this is here so you can swap to
# nginx "just in case". Because both are Gateway API, the HTTPRoutes + BackendTLSPolicy are
# unchanged — only the Gateway's gatewayClassName differs.
#
# To switch Traefik -> nginx:
#   1. Comment out module "traefik" (keep module "traefik-crds" — the Gateway API CRDs are
#      shared and controller-agnostic).
#   2. Uncomment this module + the nginx_conf input in terragrunt.hcl.
#   3. In routing_conf: set route_type = "nginx" and add a `gateways` entry (NGF makes no
#      Gateway of its own), then point each httproute's gateway_name/namespace at it.
# NGF creates GatewayClass "nginx"; it provisions a data-plane + LoadBalancer per Gateway.
#
# module "nginx-gateway-fabric" {
#   source                 = "../../shared/helm"
#   enabled                = local.enabled
#   environment            = var.environment
#   name                   = var.nginx_conf.helm.release_name # must equal the OCI chart name
#   namespace              = var.nginx_conf.helm.namespace
#   repository             = var.nginx_conf.helm.repository    # oci://ghcr.io/nginx/charts
#   chart_version          = var.nginx_conf.helm.chart_version # 2.6.6 (app 2.6.6)
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     common = var.nginx_conf.common
#   }
#   depends_on = [module.traefik-crds] # Gateway API CRDs must exist first
# }

module "vault" {
  source                 = "../../shared/helm"
  enabled                = local.enabled
  environment            = var.environment
  name                   = local.vault_helm.release_name
  namespace              = local.vault_helm.namespace
  repository             = local.vault_helm.repository
  chart_version          = local.vault_helm.chart_version
  values_type            = local.vault_helm.values_type
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    server = local.vault_server
    ui     = local.vault_ui
    common = local.vault_common
  }

  # cert-manager must be installed (CRDs + controller) before Vault's pre-helm
  # Issuer/Certificate manifests (vault/tls.yml.tftpl) can apply.
  depends_on = [module.cert-manager]
}

module "external-secrets" {
  source                 = "../../shared/helm"
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
  }
}

# Gateway API routes on the self-managed Traefik v3: HTTPRoutes + BackendTLSPolicy for the
# UIs (e.g. Vault). Applied AFTER traefik (Gateway/GatewayClass + CRDs) and vault (so the
# vault-active Service + cert-manager CA Secret exist). Enabled by removing the module-local
# kubectl provider block (see routing/providers.tf) so depends_on is allowed.
module "gateway-routes" {
  source                 = "../../shared/routing"
  enabled                = local.enabled
  environment            = var.environment
  namespace              = local.routing_namespace
  route_type             = local.routing_route_type
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    routing = {
      gateways             = local.routing_gateways
      httproutes           = local.routing_httproutes
      backend_tls_policies = local.routing_backend_tls_policies
      dashboard_routes     = local.routing_dashboard_routes
    }
  }

  depends_on = [module.traefik, module.vault]
}

# module "reloader" {
#   source                 = "../helm"
#   enabled                = local.enabled
#   environment            = var.environment
#   name                   = local.reloader_helm.release_name
#   namespace              = local.reloader_helm.namespace
#   repository             = local.reloader_helm.repository
#   chart_version          = local.reloader_helm.chart_version
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     common = local.reloader_common
#   }
# }

# resource "null_resource" "ex_secrets_ready" {
#   depends_on = [module.external-secrets]
# }

# module "argocd" {
#   source                 = "../helm"
#   enabled                = local.enabled
#   environment            = var.environment
#   name                   = local.argocd_helm.release_name
#   namespace              = local.argocd_helm.namespace
#   repository             = local.argocd_helm.repository
#   chart_version          = local.argocd_helm.chart_version
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     common  = local.argocd_common
#     ingress = local.argocd_ingress
#     github  = local.argocd_github
#     secret  = local.argocd_secret
#   }
#
#   # depends_on = [null_resource.ex_secrets_ready]
# }

# module "argocd-img-update" {
#   source                 = "../helm"
#   enabled                = local.enabled
#   environment            = var.environment
#   name                   = local.argocd_img_upd_helm.release_name
#   namespace              = local.argocd_img_upd_helm.namespace
#   repository             = local.argocd_img_upd_helm.repository
#   chart_version          = local.argocd_img_upd_helm.chart_version
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     common = merge(local.argocd_img_upd_common, {
#       argocd_server_url = module.argocd.argocd_server_url
#     })
#     docker = local.argocd_img_upd_docker
#     # docker = merge(
#     #   local.argocd_img_upd_docker, {
#     #     images = join(",",
#     #     formatlist("${local.argocd_img_upd_docker.organization}/%s", [for img in local.images_upd : "${img.name}:${img.version}"]))
#     #   }
#     # )
#     # github = local.argocd_img_upd_github
#
#   }
#
#   # depends_on = [null_resource.ex_secrets_ready]
# }

# module "consul" {
#   source                 = "../helm"
#   enabled                = local.disabled
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

# module "kafka" {
#   source                 = "../helm"
#   enabled                = local.disabled
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

# module "argocd-routing" {
#   source                 = "../routing"
#   enabled                = local.disabled
#   environment            = var.environment
#   namespace              = local.argocd_helm.namespace
#   host                   = var.host
#   client_key             = var.client_key
#   client_certificate     = var.client_certificate
#   cluster_ca_certificate = var.cluster_ca_certificate
#   token                  = var.token
#   tags                   = var.tags
#   parameters = {
#     routing = local.argocd_routing
#   }
# }

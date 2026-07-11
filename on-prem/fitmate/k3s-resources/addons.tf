locals {
  # CoreDNS is managed by k3s itself (rancher/mirrored-coredns-coredns:1.11.3) since the lab
  # no longer passes --disable=coredns. The terraform core-dns module below is commented out
  # so it doesn't fight k3s for the kube-system coredns/kube-dns resources.
  # coredns_helm   = var.coredns_conf.helm
  # coredns_common = var.coredns_conf.common

  cert_manager_helm   = var.cert_manager_conf.helm
  cert_manager_common = var.cert_manager_conf.common

  # Self-managed Traefik v3 (k3s-bundled v2.11 disabled via `--disable=traefik`). ONE
  # controller handles everything at once: Kubernetes Ingress (Vault), Traefik CRD/IngressRoute
  # (dashboard + Vault's ServersTransport), and Gateway API (services deployed later). Gateway
  # API CRDs come from module "gateway-api-crds" (shared/crds); the traefik.io CRDs come from
  # the traefik chart's OWN crds/ dir (so no traefik-io bundle needed here).
  #
  # Vault deliberately stays on its Ingress + ServersTransport — NOT Gateway API — because
  # Traefik's BackendTLSPolicy can't verify Vault's HTTPS backend (verifies the pod IP,
  # traefik/traefik#12127). On self-managed v3 the ServersTransport IS honored (unlike the
  # broken bundle), so the Ingress path works. New HTTP services use Gateway API HTTPRoutes.
  gateway_api_crd_files = ["gateway-api-standard-v1.5.1.yaml"] # Gateway API standard channel
  crd_files             = local.gateway_api_crd_files

  traefik_helm    = var.traefik_conf.helm
  traefik_common  = var.traefik_conf.common
  traefik_routing = try(var.traefik_conf.routing, {})

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

# Gateway API standard-channel CRDs (Gateway/GatewayClass/HTTPRoute/BackendTLSPolicy) —
# server-side-applied, NOT Helm (the traefik-crds chart's 3.1 MB blows etcd's 1 MiB release
# Secret cap). Must land BEFORE the traefik release, whose Gateway/GatewayClass resources
# render against them. Traefik's OWN traefik.io CRDs come from the traefik chart's crds/ dir.
module "gateway-api-crds" {
  source    = "../../shared/crds"
  enabled   = local.enabled
  crd_files = local.crd_files
}

# Self-managed Traefik v3 controller (replaces the disabled bundled v2.11). Serves the Vault
# Ingress, the dashboard IngressRoute, and Gateway API HTTPRoutes for future services. Its
# chart installs the traefik.io CRDs (ServersTransport, IngressRoute) that Vault + the
# dashboard depend on.
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

  depends_on = [module.gateway-api-crds]
}

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

  # cert-manager (CRDs + controller) before Vault's pre-helm Issuer/Certificate manifests
  # (vault/tls.yml.tftpl); traefik before Vault's ServersTransport template — the traefik chart
  # installs the traefik.io ServersTransport CRD, and the Ingress needs Traefik running to route.
  depends_on = [module.cert-manager, module.traefik]
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

# Traefik dashboard route (IngressRoute → api@internal). Vault is NOT here — it routes via its
# own Ingress (server.ingress.enabled) + ServersTransport, so there's no vault-routing module.
# Future HTTP services each add an HTTPRoute (Gateway API) pointing at the traefik-gateway.
module "traefik-routing" {
  source                 = "../../shared/routing"
  enabled                = local.enabled
  environment            = var.environment
  namespace              = local.traefik_helm.namespace
  route_type             = var.route_type
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    routing = local.traefik_routing
  }

  depends_on = [module.traefik]
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

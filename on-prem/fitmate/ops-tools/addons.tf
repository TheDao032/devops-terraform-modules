locals {
  disabled = 0
  enabled  = 1

  # CoreDNS is managed by k3s itself (rancher/mirrored-coredns-coredns:1.11.3) since the lab
  # no longer passes --disable=coredns. The terraform core-dns module below is commented out
  # so it doesn't fight k3s for the kube-system coredns/kube-dns resources.
  # coredns_helm   = var.coredns_conf.helm
  # coredns_common = var.coredns_conf.common

  # cert_manager_enabled = length(var.cert_manager_conf) > 0 ? local.enabled : local.disabled
  # cert_manager_helm    = try(var.cert_manager_conf.helm, {})
  # cert_manager_common  = try(var.cert_manager_conf.common, {})

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
  # gateway_api_crd_files = ["gateway-api-standard-v1.5.1.yaml"] # Gateway API standard channel
  # crd_files             = local.gateway_api_crd_files
  #
  # traefik_enabled = length(var.traefik_conf) > 0 ? local.enabled : local.disabled
  # traefik_helm    = try(var.traefik_conf.helm, {})
  # traefik_common  = try(var.traefik_conf.common, {})
  # traefik_routing = try(var.traefik_conf.routing, {})
  #
  # vault_enabled = length(var.traefik_conf) > 0 ? local.enabled : local.disabled
  # vault_helm    = try(var.vault_conf.helm, {})
  # vault_server  = try(var.vault_conf.server, {})
  # vault_ui      = try(var.vault_conf.ui, {})
  # vault_common  = try(var.vault_conf.common, {})

  # external_secrets_enabled = length(var.external_secrets_conf) > 0 ? local.enabled : local.disabled
  # external_secrets_helm    = try(var.external_secrets_conf.helm, {})
  # external_secrets_common  = try(var.external_secrets_conf.common, {})
  # external_secrets_secret = var.external_secrets_conf.secret

  # kafka_helm       = var.kafka_conf.helm
  # kafka_controller = var.kafka_conf.controller
  # kafka_broker     = var.kafka_conf.broker
  # kafka_sasl       = var.kafka_conf.sasl

  # ArgoCD (core). Enabled only when the env supplies argocd_conf — so the FIRST bring-up pass
  # (no argocd_conf) skips it, and a SECOND pass (after vault-secrets + external-secrets are
  # applied and feed argocd_conf via terragrunt dependencies) turns it on. This two-pass model
  # is deliberate: argocd_conf reads outputs from stacks that themselves depend on THIS stack's
  # Vault + ESO-operator, so it can't resolve until they're up. Locals are try()-guarded so an
  # empty argocd_conf doesn't error while disabled.
  argocd_enabled = length(var.argocd_conf) > 0 ? local.enabled : local.disabled
  argocd_helm    = try(var.argocd_conf.helm, {})
  argocd_github  = try(var.argocd_conf.github, {})
  argocd_common  = try(var.argocd_conf.common, {})
  argocd_ingress = try(var.argocd_conf.ingress, {})
  argocd_secret  = try(var.argocd_conf.secret, {})
  argocd_routing = try(var.argocd_conf.routing, {})

  # argocd_img_upd_helm   = var.argocd_img_upd_conf.helm
  # argocd_img_upd_docker = var.argocd_img_upd_conf.docker
  # argocd_img_upd_common = var.argocd_img_upd_conf.common

  # reloader_enabled = length(var.reloader_conf) > 0 ? local.enabled : local.disabled
  # reloader_helm    = try(var.reloader_conf.helm)
  # reloader_common  = try(var.reloader_conf.common)

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

# resource "null_resource" "ex_secrets_ready" {
#   depends_on = [module.external-secrets]
# }

# ArgoCD (core) — Helm install into the gitops namespace. Repo creds (SSH key) are embedded via
# the chart's credentialTemplates (from Vault, at plan time); the chart's ExternalSecrets (docker
# + argocd creds) apply AFTER the release and reconcile once the gitops SecretStore exists (from
# the external-secrets stack). server.insecure=true → plain-HTTP backend for the HTTPRoute below.
module "argocd" {
  source                 = "../../shared/helm"
  enabled                = local.argocd_enabled
  environment            = var.environment
  name                   = try(local.argocd_helm.release_name, "argocd")
  namespace              = try(local.argocd_helm.namespace, "argocd")
  repository             = try(local.argocd_helm.repository, "")
  chart_version          = try(local.argocd_helm.chart_version, "")
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

  # ESO operator (for the chart's ExternalSecrets) + Vault (source of the embedded repo creds).
  # depends_on = [module.external-secrets, module.vault]
}

# ArgoCD UI/API exposure — Gateway API HTTPRoute on the shared traefik-gateway `web` listener
# (from:All allows this cross-namespace route from `gitops`). Backend is argocd-server on :80
# (HTTP, because server.insecure=true). Consistent with "new HTTP services use Gateway API".
module "argocd-routing" {
  source                 = "../../shared/routing"
  enabled                = local.argocd_enabled
  environment            = var.environment
  namespace              = try(local.argocd_helm.namespace, "argocd")
  route_type             = var.route_type
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    routing = local.argocd_routing
  }

  depends_on = [module.argocd]
}

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

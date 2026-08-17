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

  # Kafka (Bitnami Apache Kafka, KRaft, in-cluster only). Enabled only when the env supplies
  # kafka_conf. try()-guarded so an empty conf resolves to safe defaults while disabled. No `broker`
  # block: KRaft runs combined (controllerOnly=false) so only the controller pool is used.
  kafka_enabled    = length(var.kafka_conf) > 0 ? local.enabled : local.disabled
  kafka_helm       = try(var.kafka_conf.helm, {})
  kafka_controller = try(var.kafka_conf.controller, {})
  kafka_sasl       = try(var.kafka_conf.sasl, {})
  kafka_common     = try(var.kafka_conf.common, {})

  # Redis (Bitnami Redis, standalone, in-cluster only). Enabled only when the env supplies redis_conf
  # (same gate as kafka). try()-guarded so an empty conf resolves to safe defaults while disabled. No
  # replica/sentinel block: architecture=standalone in the values template uses only the master pool.
  redis_enabled = length(var.redis_conf) > 0 ? local.enabled : local.disabled
  redis_helm    = try(var.redis_conf.helm, {})
  redis_master  = try(var.redis_conf.master, {})
  redis_auth    = try(var.redis_conf.auth, {})
  redis_common  = try(var.redis_conf.common, {})

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

  # Keycloak (operator-based). Enabled only when the env supplies keycloak_conf. try()-guarded so
  # an empty conf resolves to safe defaults while disabled.
  keycloak_enabled = length(var.keycloak_conf) > 0 ? local.enabled : local.disabled
  keycloak_kc      = try(var.keycloak_conf.keycloak, {})
  keycloak_db      = try(var.keycloak_conf.db, {})
  keycloak_admin   = try(var.keycloak_conf.admin, {})
  keycloak_routing = try(var.keycloak_conf.routing, {})

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

# Keycloak (self-hosted IAM) via the Keycloak OPERATOR. This applies the operator Deployment + the
# Keycloak CR; the CRDs are installed cluster-once by init-resources' crds module. Keycloak connects
# to the EXTERNAL Citus Postgres (coordinator :5432, db=keycloak) — NOT in-cluster, NOT pgbouncer.
# Admin bootstrap = the operator's auto-generated keycloak-initial-admin Secret.
module "keycloak" {
  source                      = "../../shared/helm"
  enabled                     = local.keycloak_enabled
  environment                 = var.environment
  name                        = "keycloak-operator"
  namespace                   = try(local.keycloak_kc.namespace, "keycloak")
  repository                  = ""
  chart_version               = ""
  helm_release_enabled        = false                                        # manifest mode: raw operator YAML + Keycloak CR, not a Helm chart
  server_side_apply           = true                                         # operator ClusterRoles exceed the client-side last-applied annotation limit
  manifest_override_namespace = try(local.keycloak_kc.namespace, "keycloak") # upstream operator bundle ships namespace-less
  host                        = var.host
  client_key                  = var.client_key
  client_certificate          = var.client_certificate
  cluster_ca_certificate      = var.cluster_ca_certificate
  token                       = var.token
  tags                        = var.tags
  parameters = {
    keycloak = {
      # FALLBACK is functional, not decorative: if keycloak_kc.hostname is unset this value is
      # what the Keycloak CR is deployed with, and it becomes the `iss` claim of every token
      # the realm issues. The lab domain is .k3s.fitmate — keycloak.k3s.local is dead.
      # gitleaks:allow — a DNS hostname, not a credential. gitleaks' generic-api-key rule
      # scores "keycloak.k3s.fitmate" at entropy 3.68 purely because "fitmate" is not a
      # dictionary word (the old .k3s.local passed for that reason alone).
      hostname  = try(local.keycloak_kc.hostname, "keycloak.k3s.fitmate") # gitleaks:allow
      instances = try(local.keycloak_kc.instances, 1)
      image     = try(local.keycloak_kc.image, "")
    }
    db = {
      host     = try(local.keycloak_db.host, "")
      port     = try(local.keycloak_db.port, 5432)
      database = try(local.keycloak_db.database, "keycloak")
      username = try(local.keycloak_db.username, "")
      password = try(local.keycloak_db.password, "")
    }
    admin = {
      username = try(local.keycloak_admin.username, "admin")
      password = try(local.keycloak_admin.password, "")
    }
  }
}

# Keycloak UI/API exposure — Gateway API HTTPRoute on the shared traefik-gateway `web` listener,
# backend = the operator's keycloak-service :8080 (httpEnabled). Same pattern as argocd-routing.
module "keycloak-routing" {
  source                 = "../../shared/routing"
  enabled                = local.keycloak_enabled
  environment            = var.environment
  namespace              = try(local.keycloak_kc.namespace, "keycloak")
  route_type             = var.route_type
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    routing = local.keycloak_routing
  }

  depends_on = [module.keycloak]
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

# Kafka (Bitnami Apache Kafka, KRaft, IN-CLUSTER ONLY) — Helm install into the `tools` namespace.
# Enabled only when the env supplies kafka_conf (same gate as argocd/keycloak). The shared/helm module
# renders charts/kafka/values.yml.tftpl against these `parameters` sub-maps (common/controller/sasl) —
# same structured-parameters style as the argocd/keycloak modules above, NOT a pre-rendered values blob.
# externalAccess is DISABLED in the template → consumers use cluster DNS: kafka.tools.svc.cluster.local:9092.
module "kafka" {
  source                 = "../../shared/helm"
  enabled                = local.kafka_enabled
  environment            = var.environment
  name                   = try(local.kafka_helm.release_name, "kafka")
  namespace              = try(local.kafka_helm.namespace, "tools")
  repository             = try(local.kafka_helm.repository, "")
  chart_version          = try(local.kafka_helm.chart_version, "")
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common     = local.kafka_common
    controller = local.kafka_controller
    sasl       = local.kafka_sasl
  }
}

# Redis (Bitnami Redis, STANDALONE, IN-CLUSTER ONLY) — Helm install into the `tools` namespace.
# Enabled only when the env supplies redis_conf (same gate as kafka). The shared/helm module renders
# charts/redis/values.yml.tftpl against these `parameters` sub-maps (common/master/auth) — same
# structured-parameters style as the kafka/argocd/keycloak modules above, NOT a pre-rendered values
# blob. No external access in the template → consumers use cluster DNS: the master Service is
# <release>-redis-master.tools.svc.cluster.local:6379 (release `redis` → redis-redis-master).
module "redis" {
  source                 = "../../shared/helm"
  enabled                = local.redis_enabled
  environment            = var.environment
  name                   = try(local.redis_helm.release_name, "redis")
  namespace              = try(local.redis_helm.namespace, "tools")
  repository             = try(local.redis_helm.repository, "")
  chart_version          = try(local.redis_helm.chart_version, "")
  host                   = var.host
  client_key             = var.client_key
  client_certificate     = var.client_certificate
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.token
  tags                   = var.tags
  parameters = {
    common = local.redis_common
    master = local.redis_master
    auth   = local.redis_auth
  }
}

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

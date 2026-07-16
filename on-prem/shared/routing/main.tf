locals {
  routing = var.parameters.routing

  # Gateway API resources (route_type must expose <route_type>/gateway-api/*.yml.tftpl).
  # httproutes:           HTTPRoute per entry (host/path -> backend Service).
  # backend_tls_policies: BackendTLSPolicy per entry (re-encrypt to a private-CA TLS backend,
  #                       e.g. Vault; caCertificateRefs -> a Secret needs Traefik v3.7+).
  httproutes           = local.routing != {} && can(var.parameters.routing.httproutes) ? var.parameters.routing.httproutes : []
  backend_tls_policies = local.routing != {} && can(var.parameters.routing.backend_tls_policies) ? var.parameters.routing.backend_tls_policies : []

  # gateways: create Gateway resources (needed for nginx/NGF, whose chart makes no Gateway;
  # for Traefik the chart makes its own, so leave this empty there).
  gateways     = local.routing != {} && can(var.parameters.routing.gateways) ? var.parameters.routing.gateways : []
  gateway_file = "${path.module}/${var.route_type}/gateway-api/gateway.yml.tftpl"

  httproute_file        = "${path.module}/${var.route_type}/gateway-api/httproute.yml.tftpl"
  backendtlspolicy_file = "${path.module}/${var.route_type}/gateway-api/backendtlspolicy.yml.tftpl"

  # NOTE: the Traefik dashboard is no longer rendered here — it's exposed by the Traefik CHART's
  # built-in IngressRoute (ingressRoute.dashboard.enabled in charts/traefik/values.yml.tftpl).
}

# ── Gateway API ────────────────────────────────────────────────────────────────
resource "kubectl_manifest" "gateway" {
  count = length(local.gateways)

  yaml_body = templatefile(local.gateway_file,
    {
      gateway   = local.gateways[count.index]
      namespace = local.gateways[count.index].namespace
    }
  )
}

resource "kubectl_manifest" "httproute" {
  count = length(local.httproutes)

  yaml_body = templatefile(local.httproute_file,
    {
      route     = local.httproutes[count.index]
      namespace = local.httproutes[count.index].namespace
    }
  )

  depends_on = [kubectl_manifest.gateway]
}

# BackendTLSPolicy attaches to the backend Service and tells the gateway how to validate
# the upstream TLS cert (the Gateway-API-native replacement for a Traefik ServersTransport).
resource "kubectl_manifest" "backend_tls_policy" {
  count = length(local.backend_tls_policies)

  yaml_body = templatefile(local.backendtlspolicy_file,
    {
      policy    = local.backend_tls_policies[count.index]
      namespace = local.backend_tls_policies[count.index].namespace
    }
  )
}

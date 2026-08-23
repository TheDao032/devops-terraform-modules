locals {
  routing = var.parameters.routing

  # Gateway API resources (route_type must expose <route_type>/gateway-api/*.yml.tftpl).
  # httproutes:           HTTPRoute per entry (host/path -> backend Service).
  # backend_tls_policies: BackendTLSPolicy per entry (re-encrypt to a private-CA TLS backend,
  #                       e.g. Vault; caCertificateRefs -> a Secret needs Traefik v3.7+).
  # try(), NOT a conditional. A `cond ? tuple : []` forces Terraform to unify both branches, and a
  # tuple of NON-IDENTICAL objects cannot collapse to a list — so it fails with "Inconsistent
  # conditional result types … the 'true' tuple has length 3, but the 'false' tuple has length 0",
  # which reads as a length problem when the real cause is heterogeneous elements.
  #
  # This lay dormant for as long as every route in a list happened to carry exactly the same
  # attributes. Adding optional `section_names` to only some routes broke it immediately. try()
  # returns the first expression that succeeds without unifying types, so optional per-entry keys
  # stay optional.
  httproutes           = try(var.parameters.routing.httproutes, [])
  backend_tls_policies = try(var.parameters.routing.backend_tls_policies, [])

  # gateways: create Gateway resources (needed for nginx/NGF, whose chart makes no Gateway;
  # for Traefik the chart makes its own, so leave this empty there).
  gateways     = try(var.parameters.routing.gateways, [])
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

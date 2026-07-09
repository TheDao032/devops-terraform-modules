locals {
  routing                   = var.parameters.routing
  middleware_strip_prefixes = local.routing != {} && can(var.parameters.routing.middleware_strip_prefixes) ? var.parameters.routing.middleware_strip_prefixes : []
  ingressroutes             = local.routing != {} && can(var.parameters.routing.ingressroutes) ? var.parameters.routing.ingressroutes : []

  middle_file      = "${path.module}/${var.route_type}/middle.yml.tftpl"
  ingroute_file    = "${path.module}/${var.route_type}/ingroute.yml.tftpl"
  middle_created   = length(local.middleware_strip_prefixes) > 0 ? length(local.middleware_strip_prefixes) : 0
  ingroute_created = length(local.ingressroutes) > 0 ? length(local.ingressroutes) : 0

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

  # Traefik dashboard is api@internal (not a k8s Service) so it can't be an HTTPRoute — it
  # gets a Traefik-native IngressRoute instead (mixed model). traefik-only.
  dashboard_routes = local.routing != {} && can(var.parameters.routing.dashboard_routes) ? var.parameters.routing.dashboard_routes : []
  dashboard_file   = "${path.module}/${var.route_type}/dashboard.yml.tftpl"
}

resource "kubectl_manifest" "middle_strip_prefix" {
  count = local.middle_created

  yaml_body = templatefile(local.middle_file,
    {
      name      = local.middleware_strip_prefixes[count.index].name
      prefixes  = local.middleware_strip_prefixes[count.index].prefixes
      namespace = local.middleware_strip_prefixes[count.index].namespace
    }
  )
}

resource "kubectl_manifest" "ingress_route" {
  count = local.ingroute_created
  yaml_body = templatefile(local.ingroute_file,
    {
      ingress_route_name     = local.ingressroutes[count.index].ingress_route_name
      middleware_annotations = local.ingressroutes[count.index].middleware_annotations
      match_condition        = local.ingressroutes[count.index].match_condition
      middlewares            = local.ingressroutes[count.index].middlewares
      services               = local.ingressroutes[count.index].services
      namespace              = local.ingressroutes[count.index].namespace
    }
  )

  depends_on = [
    kubectl_manifest.middle_strip_prefix,
  ]
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

resource "kubectl_manifest" "dashboard" {
  count = length(local.dashboard_routes)

  yaml_body = templatefile(local.dashboard_file,
    {
      route     = local.dashboard_routes[count.index]
      namespace = local.dashboard_routes[count.index].namespace
    }
  )
}

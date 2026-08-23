variable "environment" {
  description = "Environment name — available to the rendered Gateway API templates."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "namespace" {
  description = "Default namespace for the routing resources (each entry may still carry its own .namespace)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid RFC 1123 DNS label (lowercase alphanumeric and '-', max 63 chars)."
  }
}

variable "enabled" {
  description = "Toggle (1 = create resources, 0 = skip)."
  type        = number
  default     = 1

  validation {
    condition     = contains([0, 1], var.enabled)
    error_message = "enabled must be 0 or 1."
  }
}

variable "route_type" {
  description = "Gateway controller flavor — selects the <route_type>/gateway-api/*.tftpl template dir."
  type        = string
  default     = "traefik"

  validation {
    condition     = contains(["traefik", "nginx"], var.route_type)
    error_message = "Allowed values for config are: 'traefik', or 'nginx'."
  }
}

variable "parameters" {
  description = <<-EOT
    Routing config. The module reads `parameters.routing`, which may be `{}` (nothing to render)
    or a map with any of these lists — each entry rendered into a Gateway API manifest:

      routing.httproutes[]           = { name, namespace, gateway_name, gateway_namespace,
                                         section_name, hostnames = list(string), path_prefix,
                                         backend_name, backend_port = number }
      routing.backend_tls_policies[] = { name, namespace, service_name, ca_secret_name, hostname }
      routing.gateways[]             = { name, namespace,
                                         listeners = list({ name, protocol, port, from }) }

    Kept `any` because `routing` is accessed via can()/!= {} guards and may be an empty map or a
    partial subset of the keys above (callers pass only the lists they need).
  EOT
  # intentionally any: routing is guarded by can()/!= {}; may be {} or a partial subset of
  # httproutes/backend_tls_policies/gateways, each a list of objects (see description).
  type    = any
  default = {}

  validation {
    condition     = can(keys(var.parameters))
    error_message = "parameters must be a map (typically { routing = {...} })."
  }

  validation {
    # When routing.httproutes is present, every entry must carry the fields the template renders.
    condition = !can(var.parameters.routing.httproutes) ? true : alltrue([
      for r in var.parameters.routing.httproutes :
      length(trimspace(tostring(r.name))) > 0 &&
      length(trimspace(tostring(r.backend_name))) > 0 &&
      can(tonumber(r.backend_port)) &&
      can(tolist(r.hostnames))
    ])
    error_message = "parameters.routing.httproutes[*] must set name, backend_name, a numeric backend_port, and a hostnames list."
  }

  validation {
    # A route that PINS forwarded headers (IN-20) must serve exactly ONE hostname.
    #
    # request_headers renders a RequestHeaderModifier that SETs X-Forwarded-Host/Proto to a fixed
    # value for every request matching the route. If the route listed two hostnames, both would be
    # stamped with the same pinned value — so the second hostname would advertise the first one's
    # identity, and any issuer derived from it would be wrong. Caught here rather than at runtime,
    # where the symptom is a token that fails an issuer check for no visible reason.
    condition = !can(var.parameters.routing.httproutes) ? true : alltrue([
      for r in var.parameters.routing.httproutes :
      try(length(r.request_headers), 0) == 0 || length(r.hostnames) == 1
    ])
    error_message = "parameters.routing.httproutes[*] that sets request_headers must list exactly one hostname (pinned headers cannot be correct for two hosts). Split it into one route per hostname."
  }

  validation {
    # When routing.gateways is present, every entry must carry a listeners list.
    condition = !can(var.parameters.routing.gateways) ? true : alltrue([
      for g in var.parameters.routing.gateways :
      length(trimspace(tostring(g.name))) > 0 && can(tolist(g.listeners))
    ])
    error_message = "parameters.routing.gateways[*] must set name and a listeners list."
  }
}

variable "tags" {
  description = "Resource tags applied where the provider supports them."
  type        = map(string)
  default     = {}
}

variable "host" {
  description = "Kubernetes API server URL for the kubectl/helm providers."
  type        = string

  validation {
    condition     = length(trimspace(var.host)) > 0
    error_message = "host must be a non-empty Kubernetes API server URL."
  }
}

# NOTE: `token` vs `client_certificate`/`client_key` are MUTUALLY-EXCLUSIVE auth methods —
# a cert-auth cluster (k3s) passes the certs + an EMPTY token; a token-auth cluster (EKS,
# service-account) passes the token + EMPTY certs. So NONE of these may be validated
# non-empty (doing so breaks the other auth method). The kubectl/helm provider surfaces a
# real auth error if all are missing.
variable "client_key" {
  description = "PEM-encoded client private key for Kubernetes API auth (empty for token-auth clusters)."
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "PEM-encoded client certificate for Kubernetes API auth (empty for token-auth clusters)."
  type        = string
}

variable "cluster_ca_certificate" {
  description = "PEM-encoded cluster CA certificate used to verify the Kubernetes API server (may be empty)."
  type        = string
}

variable "token" {
  description = "Bearer token for Kubernetes API auth (empty for cert-auth clusters like k3s)."
  type        = string
  sensitive   = true
}

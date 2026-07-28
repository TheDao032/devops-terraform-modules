# variable "coredns_chart_info" {
#   description = "alloy Conf Data"
#   type        = map(any)
#   default     = {}
# }
#
# variable "coredns_conf" {
#   description = "alloy Conf Data"
#   type        = map(any)
#   default     = {}
# }
#

variable "environment" {
  description = "Environment name — available to dashboard templates."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "traefik_conf" {
  description = <<-EOT
    Traefik config data. The module reads `.namespace` (the namespace the dashboard
    IngressRoute is rendered into); the rest is freeform, so it stays `any`.
  EOT
  # intentionally any: freeform Traefik config, module only reads .namespace
  type    = map(any)
  default = {}

  validation {
    condition     = can(keys(var.traefik_conf))
    error_message = "traefik_conf must be a map."
  }
}

variable "coredns_conf" {
  description = "CoreDNS config data (freeform, template-consumed)."
  # intentionally any: freeform CoreDNS config map
  type    = map(any)
  default = {}

  validation {
    condition     = can(keys(var.coredns_conf))
    error_message = "coredns_conf must be a map."
  }
}

variable "dashboard_ingroute_name" {
  description = "Name of the Traefik dashboard IngressRoute resource."
  type        = string
  default     = "traefik-dashboard"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,251}[a-z0-9])?$", var.dashboard_ingroute_name))
    error_message = "dashboard_ingroute_name must be a valid RFC 1123 subdomain name (lowercase alphanumeric and '-')."
  }
}

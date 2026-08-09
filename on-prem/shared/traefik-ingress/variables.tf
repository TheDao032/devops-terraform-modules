variable "ingress_class" {
  description = "IngressClass name (k3s = traefik)."
  type        = string
  default     = "traefik"
}

variable "routes" {
  description = <<-EOT
    host -> backend Service. Creates one Traefik Ingress per entry, SEPARATE from any Helm-managed
    *.k3s.* Ingress (so Helm never reverts it). Set `https = true` (+ `servers_transport`, a Traefik
    ServersTransport ref like "vault-backend@kubernetescrd") for TLS backends such as Vault.
    The Ingress is created in the backend's own namespace so a same-ns ServersTransport ref resolves.
  EOT
  type = map(object({
    namespace         = string
    service           = string
    port              = number
    https             = optional(bool, false)
    servers_transport = optional(string, "")
  }))
  default = {}
}

variable "traefik_dashboard" {
  description = <<-EOT
    Optional: expose the Traefik dashboard (the internal `api@internal` service, which a normal
    Ingress can't target) at this host via a Traefik IngressRoute CRD. null = skip.
  EOT
  type = object({
    host      = string
    namespace = string
  })
  default = null
}

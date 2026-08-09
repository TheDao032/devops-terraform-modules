variable "account_id" {
  description = "Cloudflare account ID (non-secret; from the dashboard URL)."
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID the hostnames live under (non-secret)."
  type        = string
}

variable "tunnel_name" {
  description = "Name of the cloudflared tunnel as it appears in the Zero Trust dashboard."
  type        = string
  default     = "fitmate-prod"
}

variable "routes" {
  description = <<-EOT
    Public hostname -> internal service, one per exposed host. `service` is the in-cluster URL
    cloudflared connects to — e.g. http://traefik.kube-system.svc.cluster.local:80 to hand off to
    Traefik by Host header, or a direct Service like https://vault-active.vault.svc.cluster.local:8200.
    A terminal `http_status:404` catch-all rule is appended automatically.
  EOT
  type = list(object({
    hostname = string
    service  = string
  }))

  validation {
    condition     = length(var.routes) > 0
    error_message = "Provide at least one hostname->service route."
  }
}

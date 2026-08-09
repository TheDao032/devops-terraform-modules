variable "namespace" {
  description = "Namespace to run the cloudflared connector in."
  type        = string
  default     = "cloudflared"
}

variable "tunnel_token" {
  description = "cloudflared run token (from the cloudflare-tunnel module's tunnel_token output)."
  type        = string
  sensitive   = true
}

variable "tunnel_name" {
  description = "Tunnel name, for labels/annotations only."
  type        = string
  default     = "fitmate-prod"
}

variable "replicas" {
  description = "cloudflared replicas. 2+ for HA (each connector opens 4 edge connections)."
  type        = number
  default     = 2
}

variable "image" {
  description = "cloudflared image (without tag)."
  type        = string
  default     = "cloudflare/cloudflared"
}

variable "image_tag" {
  description = "cloudflared image tag. Pinned (with --no-autoupdate) for reproducibility."
  type        = string
  default     = "2026.7.3"
}

variable "resources" {
  description = "Container resource requests/limits (cloudflared is lightweight)."
  type = object({
    requests = object({ cpu = string, memory = string })
    limits   = object({ cpu = string, memory = string })
  })
  default = {
    requests = { cpu = "50m", memory = "64Mi" }
    limits   = { cpu = "200m", memory = "128Mi" }
  }
}

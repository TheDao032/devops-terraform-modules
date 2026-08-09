variable "account_id" {
  description = "Cloudflare account ID (non-secret)."
  type        = string
}

variable "allowed_emails" {
  description = <<-EOT
    Emails allowed through Access. With no IdP configured, Cloudflare's built-in one-time PIN (email
    OTP) is used — the visitor enters one of these emails, gets a code, and is let in if it matches.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.allowed_emails) > 0
    error_message = "Provide at least one allowed email."
  }
}

variable "apps" {
  description = "host -> { name } for each self-hosted app to gate behind Access (e.g. vault.fitmate.me)."
  type        = map(object({ name = string }))
}

variable "session_duration" {
  description = "How long an Access session stays valid (format like 24h, 30m)."
  type        = string
  default     = "24h"
}

variable "app_name_prefix" {
  description = "Prefix for the Access application display names."
  type        = string
  default     = ""
}

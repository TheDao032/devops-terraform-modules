# Reusable Keycloak realm module — manages a realm's CONTENT (roles, clients, mappers, users) with
# the keycloak/keycloak provider. The keycloak-operator manages the SERVER; this manages what's
# inside it. Driven by one `realm` config object so each realm = a thin terragrunt unit.
#
# Provider is inherited from the terragrunt root (root.hcl versions.tf declares keycloak + vault) and
# configured by keycloak.hcl (generate) — so NO providers.tf here, same as the database module.

variable "keycloak_url" {
  description = "Base URL of Keycloak (used to render the realm issuer output). Match the provider URL, e.g. http://keycloak.k3s.fitmate."
  type        = string
}

variable "realm" {
  description = "Full realm definition: name, roles, OIDC clients (+ audiences), and seed users."
  type = object({
    name         = string
    enabled      = optional(bool, true)
    display_name = optional(string)
    # HTTP lab → "none" (Keycloak otherwise rejects HTTP logins on an external hostname).
    # Prod behind TLS → "external" (the Keycloak default).
    ssl_required = optional(string, "external")

    roles = optional(list(string), [])

    clients = optional(list(object({
      client_id                       = string
      name                            = optional(string)
      access_type                     = optional(string, "CONFIDENTIAL") # CONFIDENTIAL | PUBLIC | BEARER-ONLY
      standard_flow_enabled           = optional(bool, true)             # Authorization Code
      direct_access_grants_enabled    = optional(bool, false)            # Resource Owner Password — keep OFF
      implicit_flow_enabled           = optional(bool, false)
      service_accounts_enabled        = optional(bool, false)
      valid_redirect_uris             = optional(list(string), [])
      valid_post_logout_redirect_uris = optional(list(string), [])
      web_origins                     = optional(list(string), [])
      pkce_code_challenge_method      = optional(string) # "S256" (recommended) or null
      # Custom audiences added to this client's ACCESS token (e.g. "fitmate-backend"). Services that
      # validate `aud` require this — Keycloak's default aud is `account`, not your backend.
      audiences = optional(list(string), [])
      # Roles from the realm's built-in `realm-management` client, granted to THIS client's service
      # account — i.e. what it may do via the Keycloak ADMIN REST API. Requires
      # service_accounts_enabled = true (validated below).
      #
      # Grant the narrowest set that works: a backend that only creates users and assigns realm
      # roles needs ["manage-users", "view-users"] — NOT "realm-admin", which is full control of
      # the realm and would let a leaked client secret rewrite the whole IdP.
      #
      # Common roles: manage-users · view-users · query-users · manage-realm · view-realm ·
      # manage-clients · view-clients · realm-admin (all of the above — avoid).
      service_account_roles = optional(list(string), [])
    })), [])

    users = optional(list(object({
      username = string
      enabled  = optional(bool, true)
      email    = optional(string)
      # Keycloak 26 declarative user profile marks firstName/lastName/email required by default, so a
      # seed user missing them triggers VERIFY_PROFILE at login → direct-grant fails with "Account is
      # not fully set up" (even though the user's requiredActions list is empty). Set these on any
      # user that must authenticate non-interactively (e.g. an e2e/password-grant test fixture).
      first_name     = optional(string)
      last_name      = optional(string)
      email_verified = optional(bool, false)
      realm_roles    = optional(list(string), []) # realm-role names to assign (must be in realm.roles)
    })), [])
  })

  validation {
    condition     = contains(["none", "external", "all"], var.realm.ssl_required)
    error_message = "realm.ssl_required must be one of: none, external, all."
  }

  # A client with service_account_roles but no service account has no user to grant them to:
  # keycloak_openid_client.service_account_user_id would be null and the apply fails deep inside
  # the grant resource with an opaque provider error. Catch it at plan time instead.
  validation {
    condition = alltrue([
      for c in var.realm.clients :
      c.service_accounts_enabled if length(c.service_account_roles) > 0
    ])
    error_message = "A client with service_account_roles must also set service_accounts_enabled = true."
  }
}

# User passwords, kept OUT of the realm object so they can be sourced from Vault and marked sensitive.
# Keyed by username; a username absent here gets an empty initial password (set it later).
variable "user_passwords" {
  description = "username -> password, from Vault (keycloak/<realm>/<user>/creds)."
  type        = map(string)
  default     = {}
  sensitive   = true
}

# Optional: push a client's GENERATED secret straight to Vault (TF -> Vault -> ESO -> app), so the
# confidential client secret never needs a manual copy. Uses the env-configured vault provider.
variable "vault_push" {
  description = "Push generated client secrets to Vault. clients: client_id -> { path, key }."
  type = object({
    enabled = optional(bool, false)
    mount   = optional(string, "") # KV-v2 mount (the org), e.g. \"fitmate\"
    clients = optional(map(object({
      path = string                            # secret path under the mount, e.g. \"local/website/creds\"
      key  = optional(string, "client_secret") # data key, e.g. \"AUTH_KEYCLOAK_SECRET\"
    })), {})
  })
  default = { enabled = false }
}

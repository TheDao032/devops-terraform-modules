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

    # ── Social login (IN-14) ────────────────────────────────────────────────────────────────────
    # Google/Facebook as realm IDENTITY PROVIDERS. Keycloak performs the OAuth code exchange with
    # the provider; the resulting login issues a NORMAL Keycloak JWT, so services need no change:
    #     browser -> Keycloak -> Google -> Keycloak -> app receives a Keycloak JWT
    #
    # ⚠️ The provider's client_secret is used BY KEYCLOAK and must NEVER be delivered to an
    # application (no ESO, no env var, and never as a SUPERTOKENS_* key — SuperTokens is retired;
    # see fitmate-gitops apps/trainee-service/prod/values.yaml:63). Handing it to a service gives a
    # live credential to a process with no code path that reads it.
    #
    # `client_id` is NOT secret — commit it in env.hcl so the config is self-documenting. Only
    # `client_secret` comes from .envrc.local via get_env().
    #
    # An entry whose client_secret is EMPTY is SKIPPED, not created (see locals.tf). A Keycloak IdP
    # with a blank secret still renders a button on the login page that fails at the code exchange —
    # skipping is the safe default and matches `get_env("GOOGLE_CLIENTSECRET", "")`. Which entries
    # were configured vs skipped is exposed in outputs so the skip is never silent.
    identity_providers = optional(list(object({
      alias         = string # "google" | "facebook" — selects the resource type
      client_id     = string
      client_secret = string
      enabled       = optional(bool, true)
      display_name  = optional(string)
      gui_order     = optional(string)

      # ⚠️ SECURITY — do not inherit these silently.
      #
      # trust_email = true means a social login whose email matches an existing account is trusted
      # WITHOUT verification. Combined with the default first-broker-login flow that auto-links by
      # email, anyone who can create a provider account bearing a victim's address inherits the
      # FITMate account. Keep false unless there is a written decision (ADR) saying otherwise.
      trust_email = optional(bool, false)
      # link_only = true prevents NEW users being created via this IdP — existing accounts may link
      # it, nobody can register with it. Useful to enable social login for staff only.
      link_only = optional(bool, false)
      # IMPORT (copy profile once, never update) | FORCE (re-sync on every login) | LEGACY.
      sync_mode = optional(string, "IMPORT")
      # Override the first-broker-login flow to control the account-linking behaviour explicitly
      # rather than relying on the realm default.
      first_broker_login_flow_alias = optional(string)
      hide_on_login_page            = optional(bool, false)
      default_scopes                = optional(string) # google: "openid profile email"
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

  # Only google/facebook have first-class resources in identity-providers.tf. A typo'd alias would
  # otherwise be silently dropped by the for_each filters and produce NO IdP with no error at all —
  # the exact "green apply that did nothing" failure this codebase keeps hitting.
  validation {
    condition = alltrue([
      for i in var.realm.identity_providers : contains(["google", "facebook"], i.alias)
    ])
    error_message = "realm.identity_providers[].alias must be one of: google, facebook (add a resource in identity-providers.tf to support more)."
  }

  validation {
    condition = alltrue([
      for i in var.realm.identity_providers : contains(["IMPORT", "FORCE", "LEGACY"], i.sync_mode)
    ])
    error_message = "realm.identity_providers[].sync_mode must be one of: IMPORT, FORCE, LEGACY."
  }

  # One resource per alias — two entries with the same alias would collide on the for_each key and
  # fail with an opaque duplicate-key error deep in the plan.
  validation {
    condition = length(var.realm.identity_providers) == length(distinct([
      for i in var.realm.identity_providers : i.alias
    ]))
    error_message = "realm.identity_providers[].alias must be unique."
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

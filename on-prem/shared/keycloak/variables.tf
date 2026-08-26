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

# PUBLIC, browser-facing base URL — the one an OAuth provider must redirect back to.
# Distinct from keycloak_url, which is the ADMIN/in-cluster address the Terraform provider talks to
# (http://keycloak.k3s.fitmate). Rendering broker callbacks from keycloak_url produced URLs that
# Google and Facebook reject: they require https, and that host is private plain HTTP. Anyone
# pasting the old output into a provider console got a redirect_uri that could never match.
# Defaults to keycloak_url so envs without a public host keep the previous behaviour.
variable "public_base_url" {
  description = "Public browser-facing base URL for broker callbacks, e.g. https://auth-dev.fitmate.me. Defaults to keycloak_url."
  type        = string
  default     = null
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

    # ── Login & registration policy ─────────────────────────────────────────────────────────────
    # These control what the LOGIN PAGE actually offers. Keycloak renders its form from realm
    # state, so a design that promises a field the realm has switched off ships a page that
    # rejects its own users.
    #
    # ⚠️ EVERY FLAG HERE DEFAULTS TO `false` ON PURPOSE — including login_with_email_allowed,
    # whose Keycloak *server* default is true. The provider writes a zero-value `false` for an
    # unset optional bool, so every realm this module already manages is sitting at false today
    # (verified against live fitmate-dev, 2026-08-24). Defaulting to the Keycloak default instead
    # of the observed state would silently flip stg AND prod on the next apply — an unrequested
    # behaviour change in prod, arriving as a side effect of a dev feature. Preserve reality;
    # let each env opt in explicitly.

    # Accept the email address in the identifier field. OFF renders the literal label "Username"
    # and REJECTS every user who types their email; ON renders "Username or email".
    # NOTE: this permits email as an *alternative* identifier. It does NOT make email the
    # identity — that is registration_email_as_username below, a different decision.
    login_with_email_allowed = optional(bool, false)

    # Two accounts may share an email address. MUST stay false when login_with_email_allowed or
    # registration_email_as_username is on (an email that maps to two users cannot identify one);
    # Keycloak rejects the combination server-side — validated at plan time below instead.
    duplicate_emails_allowed = optional(bool, false)

    # Self-service sign-up: renders the "Register" link and the registration form.
    # ⚠️ Pair with a plan for abuse: with registration ON and verify_email OFF, anyone may create
    # an account claiming ANY email address, unverified.
    registration_allowed = optional(bool, false)

    # Make the email address BE the username: the registration form drops its username field and
    # the login label becomes "Email". Changes the shape of the registration form, so it is a
    # product/design decision, not a toggle — agree it with whoever owns the sign-up screen.
    # Existing users keep the usernames they already have; this governs new registrations.
    registration_email_as_username = optional(bool, false)

    # 🔴 REQUIRES SMTP. Renders "Forgot password?"; Keycloak then EMAILS a reset link.
    # This module configures no smtp_server block, so on a realm without SMTP the link leads to a
    # form that can never deliver anything — a dead end that looks like a working feature.
    # Configure SMTP on the realm FIRST, then enable this.
    reset_password_allowed = optional(bool, false)

    # 🔴 REQUIRES SMTP — same trap, but worse: with no mail server a new user is handed a
    # VERIFY_EMAIL required action and an email that never arrives, locking them out of the
    # account they just created. Never enable this before SMTP exists.
    verify_email = optional(bool, false)

    # Renders the "Remember me" checkbox and honours it with a longer-lived session.
    remember_me = optional(bool, false)

    # Let users change their own username in the account console. Keep false when
    # registration_email_as_username is on, or the "email IS the identity" invariant is editable.
    edit_username_allowed = optional(bool, false)

    # ── Internationalization (i18n) ───────────────────────────────────────────────────────────────
    # Turns on Keycloak's realm-level i18n and declares which locales the login/account pages may be
    # rendered in. NULL (the default) emits NO `internationalization` block at all, which leaves the
    # realm exactly where every realm this module manages is today: i18n disabled, pages English-only.
    # That default is chosen the same way the login flags above were — to PRESERVE OBSERVED STATE, so
    # that adding this variable cannot change bosch, renesas, fitmate-stg or fitmate-prod on their
    # next apply. Each env opts in by setting the object.
    #
    # 🔑 THE LANGUAGE SWITCHER IS NOT A SEPARATE SETTING. Keycloak renders the `#kc-locale` dropdown
    # only when i18n is enabled AND `supported_locales` has MORE THAN ONE entry. A single-locale list
    # is a valid, successful apply that produces translated pages with NO way for a user to change
    # language — which looks identical to "the theme forgot the switcher". If a switcher is wanted,
    # list at least two locales.
    #
    # 🔑 ENABLING A LOCALE DOES NOT MEAN ITS STRINGS EXIST. Keycloak's non-core translations ship in
    # the `resources-community` overlay. They are present in the upstream `quay.io/keycloak/keycloak`
    # images, but ABSENT from the Red Hat build of Keycloak (`registry.redhat.io/rhbk/*`) and from any
    # custom build made with `-DskipCommunityTranslations`. On such an image the realm setting applies
    # cleanly and every string still renders in English. Verify against RENDERED BYTES, not the realm
    # setting — see README ("Verifying a locale actually renders").
    #
    # `default_locale` must be one of `supported_locales` (validated below): Keycloak falls back to it
    # whenever the request carries no usable locale hint, so a default outside the list is a fallback
    # to something the realm has not enabled.
    internationalization = optional(object({
      # Locale codes, e.g. ["vi", "en"]. >1 entry is what makes the language switcher render.
      supported_locales = list(string)
      # Locale used when the request carries no `kc_locale` param, no KEYCLOAK_LOCALE cookie, no user
      # `locale` attribute and no usable Accept-Language. Must appear in supported_locales.
      default_locale = string
    }))

    # ── Login theme ──────────────────────────────────────────────────────────────────────
    # Name of the theme Keycloak renders the LOGIN pages with. This is the `name` field inside the
    # theme JAR's META-INF/keycloak-themes.json, NOT the JAR filename. For the FitMate theme that
    # string is `fitmate` (read out of the built artifact 2026-08-26, which declares exactly one
    # theme named `fitmate` providing exactly one type, `login`).
    #
    # NULL (the default) leaves the attribute unset — the state every realm this module manages is
    # in today (live fitmate-dev reports `loginTheme: None`, and the served page is the stock
    # keycloak.v2). The provider writes a zero-value "" for an unset optional string and Keycloak
    # reads "" as "use the server default", so ADDING this variable changes nothing for bosch,
    # renesas, fitmate-stg or fitmate-prod until each one opts in. Same preserve-observed-state
    # rule as the login flags and i18n above.
    #
    # 🔴 THE THEME MUST BE IN THE SERVER IMAGE BEFORE THIS IS SET. Keycloak does NOT validate the
    # name: pointing a realm at a theme the running image does not carry is accepted by the admin
    # API and by this provider, and the realm then silently falls back to the default theme at
    # render time. The apply is green and the login page is byte-identical to before — which is
    # indistinguishable from "the theme shipped but didn't work". Roll the image
    # (parameters.keycloak.image, ops-tools) FIRST, confirm the pod is Ready on it, THEN set this.
    #
    # ⚠️ DELIBERATELY LOGIN-ONLY. `account_theme` and `email_theme` are NOT exposed by this module,
    # and that omission IS the enforcement. The FitMate JAR declares the `login` type only, so
    # pointing the account or email theme at `fitmate` would leave those pages with no templates to
    # render. Leaving them unsettable here means it cannot be done by accident from an env file.
    login_theme = optional(string)

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
      # TERRAFORM RESOURCE ADDRESS for this user — NOT the user's identity. Defaults to `username`.
      #
      # Exists because `username` is mutable server-side and the for_each key is not. Keycloak
      # REWRITES a user's username to their email when registration_email_as_username is on, so
      # correcting the config to match (per ADR-050, "the email IS the identifier") would move the
      # map key from "trainee1" to "trainee1@fitmate.local" and Terraform would DESTROY AND RECREATE
      # a user whose only change was a field it had already converged on. That recreate is not
      # cosmetic: the user gets a NEW `sub`, and initial_password is create-only.
      #
      # Set `key` to whatever the resource is ALREADY keyed by in state, then change `username`
      # freely. Leave unset for new users. Verify with `terragrunt state list` before setting it —
      # a `key` that does not match state causes the very recreate it exists to prevent.
      key      = optional(string)
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

  # Email cannot identify a user if two users may share one. Keycloak rejects this pairing
  # server-side with an opaque 400 mid-apply; failing at plan time says which two flags collided.
  validation {
    condition = !(var.realm.duplicate_emails_allowed && (
      var.realm.login_with_email_allowed || var.realm.registration_email_as_username
    ))
    error_message = "realm.duplicate_emails_allowed cannot be true together with login_with_email_allowed or registration_email_as_username — an email that maps to two accounts cannot identify one."
  }

  # registration_email_as_username means "the email IS the username". Leaving username editable
  # lets a user break that invariant from the account console after the fact.
  validation {
    condition     = !(var.realm.registration_email_as_username && var.realm.edit_username_allowed)
    error_message = "realm.registration_email_as_username requires edit_username_allowed = false — otherwise a user can edit away the email-as-identity invariant."
  }

  # An empty supported_locales with i18n enabled is accepted by the provider and produces a realm
  # with internationalization ON and nothing to render in — Keycloak silently falls back to English.
  # A green apply that did nothing, again.
  validation {
    condition = (
      var.realm.internationalization == null ||
      length(try(var.realm.internationalization.supported_locales, [])) > 0
    )
    error_message = "realm.internationalization.supported_locales must contain at least one locale."
  }

  # default_locale outside supported_locales means the realm falls back to a language it has not
  # enabled. Keycloak accepts this pairing and then serves English, which reads as "the translation
  # is missing" rather than "the default is wrong".
  validation {
    condition = (
      var.realm.internationalization == null ||
      contains(
        try(var.realm.internationalization.supported_locales, []),
        try(var.realm.internationalization.default_locale, "")
      )
    )
    error_message = "realm.internationalization.default_locale must be one of realm.internationalization.supported_locales."
  }

  # Two users resolving to the same for_each key collide with an opaque duplicate-key error deep in
  # the plan. Possible now that `key` can be set independently of `username`.
  validation {
    condition = length(var.realm.users) == length(distinct([
      for u in var.realm.users : coalesce(u.key, u.username)
    ]))
    error_message = "realm.users[] must have unique keys — each user's `key` (or `username` when `key` is unset) must be distinct."
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

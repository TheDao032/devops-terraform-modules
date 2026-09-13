resource "keycloak_realm" "main" {
  realm        = var.realm.name
  enabled      = var.realm.enabled
  display_name = try(var.realm.display_name, var.realm.name)

  # HTTP lab → "none". The issuer (http://keycloak.k3s.fitmate/realms/<name>) is fixed by the SERVER
  # hostname (Keycloak CR spec.hostname), so no realm-level frontend_url override is needed here.
  ssl_required = var.realm.ssl_required

  # ── Login & registration policy ───────────────────────────────────────────────────────────────
  # What the login page OFFERS. Keycloak renders its form from this state, so these are the flags
  # that decide whether a given field, link or checkbox exists at all.
  #
  # These were previously UNSET here, which is not the same as "Keycloak's defaults": the provider
  # sends a zero-value false for every unset optional bool, so the realms this module manages have
  # been running with all of them false — including login_with_email_allowed, whose server default
  # is true. Setting them explicitly makes that observed state visible in code instead of being an
  # emergent property of what the module forgot to send. All defaults are false (see variables.tf),
  # so this is a no-op for every existing realm until an env opts in.
  login_with_email_allowed       = var.realm.login_with_email_allowed
  duplicate_emails_allowed       = var.realm.duplicate_emails_allowed
  registration_allowed           = var.realm.registration_allowed
  registration_email_as_username = var.realm.registration_email_as_username
  remember_me                    = var.realm.remember_me
  edit_username_allowed          = var.realm.edit_username_allowed

  # 🔴 BOTH REQUIRE SMTP. reset_password_allowed renders "Forgot password?" and then tries to
  # EMAIL a reset link; verify_email hands every new registrant a VERIFY_EMAIL action satisfied
  # only by an email. With no mail server the first is a dead end and the second locks users out
  # of the account they just created — in both cases the realm looks correctly configured.
  #
  # ✅ UPDATED 2026-09-13 (ADR-094, SCRUM-450/453): this module DOES now configure SMTP — see the
  # `smtp_server` dynamic block below. The previous version of this comment said "no smtp_server
  # block anywhere", and SCRUM-453 quotes that line; it is no longer true.
  #
  # ⚠️ AN smtp_server BLOCK IS NECESSARY BUT NOT SUFFICIENT. Do not flip these two flags in the
  # same change that adds SMTP. The order that actually works:
  #   1. the mail target exists and the realm can reach it
  #   2. smtp_server points at it
  #   3. a real message is observed CAPTURED and rendering correctly (vi/en copy, working link)
  #   4. only THEN turn these on
  # Skipping (3) is how "SMTP is configured" gets mistaken for "email works". And note separately
  # that any seeded user whose address ends in a reserved TLD (.test, .local, .invalid, .example)
  # is rejected by Keycloak's own address validator BEFORE any send is attempted — so those
  # accounts stay unable to receive a reset or verification mail even with a healthy mail server.
  reset_password_allowed = var.realm.reset_password_allowed
  verify_email           = var.realm.verify_email

  # ── Login theme ───────────────────────────────────────────────────────────────────────────────
  # Which theme renders this realm's login pages. null → the attribute is left at "" → Keycloak
  # serves its default (keycloak.v2 on 26.7), which is what every realm here does today.
  #
  # Keycloak does NOT verify the theme exists. A name the running image does not carry applies
  # cleanly and then falls back at render time, so a green apply proves nothing here — the check
  # that matters is the RESOURCE PATH in the served HTML changing from
  #   /resources/<hash>/login/keycloak.v2   to   /resources/<hash>/login/fitmate
  # See variables.tf for why this is login-only and why the image must land first.
  login_theme = var.realm.login_theme

  # ── Internationalization ──────────────────────────────────────────────────────────────────────
  # DYNAMIC on purpose. An always-present block would force every caller to supply locales, and —
  # worse — writing the block with zero-value contents is NOT the same as omitting it: it flips the
  # realm's `internationalizationEnabled` to true. Every realm this module manages currently has it
  # false, so a null default that emits nothing is the only shape that leaves bosch, renesas, stg
  # and prod untouched when this variable lands.
  #
  # Keycloak renders the `#kc-locale` language dropdown ONLY when this block exists AND
  # supported_locales has >1 entry. With i18n off, the control does not exist in the DOM at all —
  # no theme can add it back, which is why this is realm config and not theme work.
  dynamic "internationalization" {
    for_each = var.realm.internationalization == null ? [] : [var.realm.internationalization]
    content {
      supported_locales = internationalization.value.supported_locales
      default_locale    = internationalization.value.default_locale
    }
  }

  # ── SMTP ──────────────────────────────────────────────────────────────────────────────────────
  # DYNAMIC on purpose, same reasoning as internationalization above: every realm this module
  # manages currently has `smtpServer: {}`, and emitting an empty block is NOT the same as
  # emitting none. A null default that renders nothing is what keeps bosch, renesas, fitmate-stg
  # and fitmate-prod untouched on their next apply now that this attribute exists.
  #
  # 🔴 NO `auth` BLOCK IS EMITTED, DELIBERATELY. In keycloak/keycloak v5.9.0 `auth` is a nested
  # block with Required username+password, so `auth = false` cannot be written at all; the
  # provider sets Auth=false precisely when the block is ABSENT. Omitting it is the mechanism,
  # not a gap. See variables.tf for the provider-source citation.
  #
  # 🔴 WHAT SETTING THIS PROVES. On dev this points at mailpit — a CATCHER. It will prove the
  # realm can open an SMTP session and that the message body renders; it proves nothing about
  # whether a human would receive it. Never cite a green dev email test as deliverability.
  #
  # WHICH ENVS MAY SET THIS: dev only, today. The catcher is dev-only by ADR-094, and pointing a
  # staging or production realm at it would mean password-reset mail silently vanishing into a
  # lab UI while the realm reports success — the failure mode this work exists to end. stg/prod
  # get a real relay, with credentials from Vault, as a separate reviewed change.
  dynamic "smtp_server" {
    for_each = var.realm.smtp_server == null ? [] : [var.realm.smtp_server]
    content {
      host = smtp_server.value.host
      from = smtp_server.value.from
      # `port` is a STRING in this provider (verified against the v5.9.0 schema), so it is passed
      # through as-is rather than coerced.
      port                  = smtp_server.value.port
      from_display_name     = smtp_server.value.from_display_name
      reply_to              = smtp_server.value.reply_to
      reply_to_display_name = smtp_server.value.reply_to_display_name
      envelope_from         = smtp_server.value.envelope_from
      starttls              = smtp_server.value.starttls
      ssl                   = smtp_server.value.ssl
      allow_utf8            = smtp_server.value.allow_utf8
    }
  }
}

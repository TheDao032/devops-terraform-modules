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

  # 🔴 BOTH REQUIRE SMTP, which this module does not configure (no smtp_server block anywhere).
  # reset_password_allowed renders "Forgot password?" and then tries to EMAIL a reset link;
  # verify_email hands every new registrant a VERIFY_EMAIL action satisfied only by an email.
  # With no mail server the first is a dead end and the second locks users out of the account they
  # just created — in both cases the realm looks correctly configured. Add SMTP before either.
  reset_password_allowed = var.realm.reset_password_allowed
  verify_email           = var.realm.verify_email
}

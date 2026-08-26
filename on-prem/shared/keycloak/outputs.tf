output "realm" {
  description = "The realm name."
  value       = keycloak_realm.main.realm
}

output "issuer" {
  description = "OIDC issuer URL — services set KEYCLOAK_ISSUER / AUTH_KEYCLOAK_ISSUER to this."
  value       = "${var.keycloak_url}/realms/${keycloak_realm.main.realm}"
}

output "client_ids" {
  description = "Map of client_id key -> client_id (handy for downstream references)."
  value       = { for k, c in keycloak_openid_client.main : k => c.client_id }
}

output "client_secrets" {
  description = "Map of client_id -> generated client secret (confidential clients). Sensitive."
  value       = { for k, c in keycloak_openid_client.main : k => c.client_secret }
  sensitive   = true
}

# ── Social-login IdPs (IN-14) ────────────────────────────────────────────────────────────────────
# Makes the "empty client_secret => skipped" behaviour INSPECTABLE. Without these, a provider whose
# secret was never exported simply doesn't appear on the login page and nothing anywhere says why —
# the silent-no-op failure mode this codebase keeps running into.
output "identity_providers" {
  description = "Aliases of social-login IdPs actually configured on the realm."
  value       = sort(concat(keys(keycloak_oidc_google_identity_provider.main), keys(keycloak_oidc_facebook_identity_provider.main)))
}

output "identity_providers_skipped" {
  description = "Aliases declared but SKIPPED because client_secret was empty (export it in .envrc.local). Not an error — but if a provider is missing from the login page, look here first."
  value       = sort(local.identity_providers_skipped)
}

# The broker callback each provider must have registered in ITS OWN console, or login fails right
# after consent. Terraform cannot register these — surfaced so the value can be copy-pasted.
output "identity_provider_redirect_uris" {
  description = "Broker redirect URIs to register at Google / Facebook. Rendered from public_base_url (the browser-facing host), NOT the in-cluster admin URL — providers require https and reject the private host."
  value = {
    for a in sort(concat(keys(keycloak_oidc_google_identity_provider.main), keys(keycloak_oidc_facebook_identity_provider.main))) :
    a => "${coalesce(var.public_base_url, var.keycloak_url)}/realms/${keycloak_realm.main.realm}/broker/${a}/endpoint"
  }
}

# ── Internationalization ─────────────────────────────────────────────────────────────────────────
# Makes "is i18n on, and would a language switcher render?" answerable from `terragrunt output`
# instead of from the admin console. The switcher is the part that surprises people: Keycloak draws
# the #kc-locale dropdown only when i18n is enabled AND more than one locale is supported, so a
# single-locale realm applies green and still has no way to change language.
#
# ⚠️ This reports the REALM SETTING ONLY. It cannot tell you whether the Keycloak image actually
# ships those locales' message bundles — community translations are absent from Red Hat builds and
# from any build using -DskipCommunityTranslations. Assert on rendered bytes for that (see README).
output "realm_locales" {
  description = "Realm i18n state: enabled, supported locales, default locale, and whether a language switcher will render (needs >1 locale). Realm setting only — does NOT prove the image ships those translations."
  value = {
    enabled            = var.realm.internationalization != null
    supported_locales  = sort(try(var.realm.internationalization.supported_locales, []))
    default_locale     = try(var.realm.internationalization.default_locale, null)
    switcher_will_show = length(try(var.realm.internationalization.supported_locales, [])) > 1
  }
}

# shared/keycloak

Reusable Terraform module that manages a **Keycloak realm's content** (roles, OIDC clients + audience
mappers, seed users) with the `keycloak/keycloak` provider (v5.x). The **keycloak-operator** manages
the *server*; this manages what's *inside* it. Drive it from one `realm` config object — each realm is
a thin terragrunt unit under `on-prem/<tenant>/<env>/keycloak/<realm>/`.

## Provider
Inherited from the terragrunt root (`root.hcl` `versions.tf` declares `keycloak` + `vault`) and
configured by `keycloak/keycloak.hcl` (a `generate` block, mirroring `database.hcl`). So there is **no
`providers.tf` here** — same convention as the on-prem database module. Auth today = password grant
(`admin-cli` + admin user/password from Vault). Upgrade path: a dedicated `terraform` service-account
client (client-credentials), no password.

## Resources
| File | Resources |
|---|---|
| `realm.tf` | `keycloak_realm` (`ssl_required="none"` for the HTTP lab, + login/registration policy) |
| `roles.tf` | `keycloak_role` (realm roles) |
| `clients.tf` | `keycloak_openid_client` + `keycloak_openid_audience_protocol_mapper` |
| `users.tf` | `keycloak_user` (+ `initial_password` from Vault) + `keycloak_user_roles` |
| `secrets.tf` | `vault_kv_secret_v2` — optional push of generated client secrets to Vault |

## Key inputs
- `keycloak_url` — base URL (for the issuer output).
- `realm` — `{ name, ssl_required, <login policy>, roles[], clients[]{…, audiences[]}, users[]{…, realm_roles[]} }`.
- `user_passwords` — `username -> password` (sensitive, from Vault).
- `vault_push` — `{ enabled, mount, clients{ client_id -> { path, key } } }` for the TF→Vault secret handoff.

## Login & registration policy

These `realm` flags decide what the **login page actually renders**. Keycloak builds its form from
realm state, so a design promising a field the realm has switched off ships a page that rejects its
own users.

| Flag | Default | Effect when `true` |
|---|---|---|
| `login_with_email_allowed` | `false` | Identifier field accepts the email. Off ⇒ label is literally `Username` and every user typing an email is rejected |
| `registration_allowed` | `false` | Renders the `Register` link + self-service sign-up form |
| `registration_email_as_username` | `false` | Email **is** the username: no username field at sign-up, login label becomes `Email` |
| `duplicate_emails_allowed` | `false` | Two accounts may share an email (mutually exclusive with the two above) |
| `reset_password_allowed` | `false` | 🔴 Renders `Forgot password?` — **requires SMTP** |
| `verify_email` | `false` | 🔴 New users must confirm by email — **requires SMTP** |
| `remember_me` | `false` | Renders the `Remember me` checkbox |
| `edit_username_allowed` | `false` | Users may change their own username |

⚠️ **Every flag defaults to `false`, including `login_with_email_allowed` — whose Keycloak *server*
default is `true`.** The provider writes a zero-value `false` for an unset optional bool, so realms
this module already manages have been running with all of them off. Defaulting to Keycloak's value
instead of the observed one would flip stg **and prod** on the next apply. Preserve reality; each
env opts in explicitly.

🔴 **`reset_password_allowed` and `verify_email` require SMTP, which this module does not
configure** — there is no `smtp_server` block. Enable either without a mail server and the realm
still looks correctly configured: the first gives a reset form that can never deliver, the second
locks every new registrant out of the account they just created. **Add SMTP first.**

Two combinations Keycloak rejects server-side are caught at plan time instead:
`duplicate_emails_allowed` with either email-identity flag, and
`registration_email_as_username` with `edit_username_allowed`.

## Seed users: `key` vs `username`

`keycloak_user` is `for_each`-ed over `realm.users`, keyed by **`key` when set, else `username`**.

`username` is **mutable server-side**: with `registration_email_as_username = true`, Keycloak
rewrites a user's username to their email. Correcting the config to match (per FitMate ADR-050,
"the email IS the identifier") would move the `for_each` key and **destroy + recreate the user** —
issuing a new `sub`, over a field Keycloak had already converged on. `initial_password` is
create-only, so the recreated user also depends on `user_passwords` still resolving.

Pin the resource address instead:

```hcl
users = [{
  key      = "trainee1"                  # what state is ALREADY keyed by — verify: terragrunt state list
  username = "trainee1@fitmate.local"    # free to change now
  ...
}]

user_passwords = {
  # 🔴 keyed by USERNAME (users.tf does lookup(var.user_passwords, each.value.username)).
  # Leave a stale key here and the lookup misses, initial_password vanishes, and the user is
  # created with NO PASSWORD — which surfaces as invalid_grant on a correctly-created user.
  "trainee1@fitmate.local" = "..."
}
```

**Adopting email-as-username in a new env**: change `username` **and** add `key` (set to the old
username) **and** rekey `user_passwords` — all in the same commit. Doing only the first plans a
destroy; doing the first two without the third silently drops the password.

## Internationalization (i18n)

`realm.internationalization` is **optional and defaults to `null`**, which emits no
`internationalization` block at all and leaves the realm i18n-disabled — the state every realm this
module manages is in today. Writing the block with empty contents is *not* the same as omitting it
(it flips `internationalizationEnabled` to true), which is why `realm.tf` uses a `dynamic` block.
Each env opts in:

```hcl
internationalization = {
  supported_locales = ["vi", "en"]   # >1 entry is what makes the switcher render
  default_locale    = "vi"           # must be one of supported_locales (validated)
}
```

### Two traps, both of which produce a green apply and a wrong page

**1. One locale enables i18n but renders no switcher.** Keycloak draws the language control only
when i18n is on *and* `supported_locales` has more than one entry. A single-locale realm applies
cleanly, translates the pages, and gives the user no way to change language — indistinguishable
from a theme that forgot the control. `terragrunt output realm_locales` reports
`switcher_will_show` so this is answerable without opening the admin console.

**2. Enabling a locale does not mean its strings exist.** Keycloak's non-core translations ship in
the `resources-community` Maven overlay. They are present in the upstream `quay.io/keycloak/keycloak`
images but **absent from the Red Hat build of Keycloak (`registry.redhat.io/rhbk/*`)** and from any
custom build using `-DskipCommunityTranslations`. On such an image the realm setting applies and
every string still renders in English.

### Verifying a locale actually renders

Assert on **rendered bytes**, never on the realm setting or a key count — both pass while the page
is still English:

```bash
curl -s -H 'Accept-Language: vi' '<login-url>' | grep -c 'Đăng nhập'   # >0 means it really rendered
```

To check the image *before* enabling a locale (no apply needed), read the message bundle out of the
running pod — `kubectl cp` fails here because the Keycloak image has no `tar`, so stream it:

```bash
kubectl -n keycloak exec keycloak-0 -- \
  cat /opt/keycloak/lib/lib/main/org.keycloak.keycloak-themes-<version>.jar > /tmp/kc-themes.jar
unzip -l /tmp/kc-themes.jar | grep 'login/messages/messages_vi.properties'
```

### The switcher's DOM id is theme-specific

In `keycloak.v2` (the default login theme in KC 26.x) the control is a native `<select>`:

```html
<select aria-label="languages" id="login-select-toggle" onchange="...">
```

It is **not** `#kc-locale` — that id belongs to the legacy `keycloak` theme. Custom themes and any
DOM assertions should target `#login-select-toggle` / `select[aria-label="languages"]`.

## Outputs
`issuer`, `client_ids`, `client_secrets` (sensitive), `realm`, `realm_locales`,
`identity_providers`, `identity_providers_skipped`, `identity_provider_redirect_uris`.

## Apply order
`vault-secrets` (generates user passwords) → this unit (creates realm/clients/users, pushes the
generated client secret to Vault). Gated (terragrunt `exclude`) on **both Keycloak and Vault** being
reachable.

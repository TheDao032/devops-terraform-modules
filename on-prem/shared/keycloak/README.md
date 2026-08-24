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

## Outputs
`issuer`, `client_ids`, `client_secrets` (sensitive), `realm`.

## Apply order
`vault-secrets` (generates user passwords) → this unit (creates realm/clients/users, pushes the
generated client secret to Vault). Gated (terragrunt `exclude`) on **both Keycloak and Vault** being
reachable.

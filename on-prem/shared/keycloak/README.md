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
| `realm.tf` | `keycloak_realm` (`ssl_required="none"` for the HTTP lab) |
| `roles.tf` | `keycloak_role` (realm roles) |
| `clients.tf` | `keycloak_openid_client` + `keycloak_openid_audience_protocol_mapper` |
| `users.tf` | `keycloak_user` (+ `initial_password` from Vault) + `keycloak_user_roles` |
| `secrets.tf` | `vault_kv_secret_v2` — optional push of generated client secrets to Vault |

## Key inputs
- `keycloak_url` — base URL (for the issuer output).
- `realm` — `{ name, ssl_required, roles[], clients[]{…, audiences[]}, users[]{…, realm_roles[]} }`.
- `user_passwords` — `username -> password` (sensitive, from Vault).
- `vault_push` — `{ enabled, mount, clients{ client_id -> { path, key } } }` for the TF→Vault secret handoff.

## Outputs
`issuer`, `client_ids`, `client_secrets` (sensitive), `realm`.

## Apply order
`vault-secrets` (generates user passwords) → this unit (creates realm/clients/users, pushes the
generated client secret to Vault). Gated (terragrunt `exclude`) on **both Keycloak and Vault** being
reachable.

# `database/postgresql` — on-prem PostgreSQL logical-object module

Manages the **logical objects** of an on-prem PostgreSQL/Citus cluster: roles, databases,
grants, schemas, extensions, seed `.sql`, pgbouncer registration, and arbitrary pre/post
actions. Tenant-**agnostic** — Terragrunt supplies the per-tenant `roles{}`/`databases{}`/
`grants[]` and the `.sql` file paths.

> Sibling engines live beside this one: `on-prem/shared/database/{mysql,mongodb,redis}` (each
> its own provider — nothing is shared between engines).

## Layering — who owns what

| Layer | Owns |
|---|---|
| **Ansible** (`devops-tools` `citus-docker` role, day-0) | containers, base `pgbouncer.ini` (`[pgbouncer]` + `app`/`*` defaults + the `%include` line), userlist, node registration |
| **This module** (Terraform, day-1/2) | roles, databases, grants, schemas, extensions, seed `.sql`, the **one** pgbouncer include file (`pgbouncer.d/databases.ini`), pre/post hooks |

Ownership is **disjoint at the file level** → the two layers never clobber each other.

## Connection model (runner is REMOTE, over SSH)

Two channels, because the halves reach the box differently:

- **Declarative half** (`cyrilgdn/postgresql` → roles/dbs/grants/schemas/extensions): speaks
  **TCP** to the coordinator. Give the runner a route to `pg_host:pg_port`, or open an SSH
  local-forward and set `pg_host = "localhost"`.
- **Imperative half** (`.sql`, pgbouncer file, reload, hooks): `local-exec` shelling `ssh` to
  `ssh_host` and running `docker exec` / `tee` / `docker kill -s HUP`. No `psql` needed on the
  runner; content is base64-framed so any characters survive.

## Prerequisite in the `citus-docker` Ansible role (already wired)

1. Base `pgbouncer.ini` contains, once: `%include /etc/pgbouncer/pgbouncer.d/databases.ini`
2. `pgbouncer.d/` is bind-mounted into the pgbouncer container and seeded with an empty
   `databases.ini` placeholder (so the `%include` resolves before Terraform first runs).

## Execution order

`pre_hooks → roles → databases → extensions → schemas → grants → seed .sql → pgbouncer → post_hooks`
(wired with `depends_on`).

## Usage (from Terragrunt)

```hcl
# devops-terragrunt-environments/<tenant>/<env>/database/terragrunt.hcl
terraform { source = ".../on-prem/shared/database/postgresql" }

inputs = {
  pg_host      = "192.168.105.10"          # coordinator (or localhost if SSH-forwarded)
  pg_superuser = "postgres"
  pg_password  = dependency.vault.outputs.pg_superuser_password

  ssh_host = "192.168.105.10"
  ssh_user = "packer"
  ssh_opts = "-i ~/.ssh/lab -o StrictHostKeyChecking=accept-new"

  # ONE block per application service — each owns its database + roles + grants + seed SQL.
  services = {
    booking-service = {
      database = {
        name       = "booking"            # explicit (hyphen-free); service key may have hyphens
        owner      = "booking_app"
        extensions = ["citus", "uuid-ossp"]
        schemas    = ["app", "audit"]
        sql_files  = ["${get_terragrunt_dir()}/sql/booking-service/0001_init.sql"]
        pgbouncer  = { register = true, pool_mode = "transaction" }
      }
      roles = {                            # keys are the real PG role names — globally unique
        booking_app = { login = true, password = local.secrets["database/booking-service/app/creds"]["password"] }
        booking_ro  = { login = true, password = local.secrets["database/booking-service/ro/creds"]["password"] }
      }
      grants = [                           # database is IMPLICIT (this service's db)
        { role = "booking_ro", schema = "app", object_type = "table", privileges = ["SELECT"] },
      ]
    }

    user-service = {
      database = { name = "users", owner = "user_app", extensions = ["uuid-ossp"], schemas = ["app"],
        sql_files = ["${get_terragrunt_dir()}/sql/user-service/0001_init.sql"] }
      roles = {
        user_app = { login = true, password = local.secrets["database/user-service/app/creds"]["password"] }
        user_ro  = { login = true, password = local.secrets["database/user-service/ro/creds"]["password"] }
      }
      grants = [{ role = "user_ro", schema = "app", object_type = "table", privileges = ["SELECT"] }]
    }
  }
}
```

Each service reads as one self-contained block. **Role names are cluster-global** in Postgres, so
keep them unique across services (convention: `<svc>_app` / `<svc>_ro`); the module validates this.

**Layouts** — the `services{}` map supports both:
- **One file** (above): every service is an entry — the whole tenant's DB layout in one place, one state.
- **Folder-per-service**: `…/database/<service>/terragrunt.hcl`, each passing `services = { <service> = {…} }`
  (one entry). Independent state + apply/destroy per service. Same module.

The `.sql` files are **tenant data** and live on the caller side (`…/database/sql/<service>/…`), never
inside this module.

## Citus caveat (multi-database)

Citus auto-propagates `CREATE ROLE`/`GRANT` to workers, so roles/grants "just work." A **new
database** is not auto-sharded, though: `extensions = ["citus"]` runs `CREATE EXTENSION citus`
in it, but you must also register the workers **for that database** (`citus_add_node` is
per-database) — do that from a `post_hook` or the Ansible role. The default `app` database is
already enabled by `citus-docker`.

## Inputs (summary)

| Group | Vars |
|---|---|
| Toggle | `enabled` |
| PG conn | `pg_host`, `pg_port`, `pg_superuser`, `pg_password` (sensitive), `pg_connect_database`, `pg_sslmode`, `pg_provider_superuser` |
| SSH | `ssh_host`, `ssh_user`, `ssh_port`, `ssh_opts`, `coordinator_container`, `pgbouncer_container`, `pgbouncer_remote_dir` |
| Objects | `services{}` (per-service `database` + `roles{}` + `grants[]`), `pre_hooks[]`, `post_hooks[]`, `tags{}` |

See `variables.tf` for the full typed schema + validations.

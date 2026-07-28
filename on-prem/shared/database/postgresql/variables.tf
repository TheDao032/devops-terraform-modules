# =============================================================================
# postgresql module — inputs. Tenant-AGNOSTIC: Terragrunt supplies the per-tenant
# roles{} / databases{} / grants[] and the .sql file paths.
# =============================================================================

variable "enabled" {
  description = "Master toggle. When false every resource's for_each collapses to empty — the module manages nothing."
  type        = bool
  default     = true
}

# ── Postgres connection (declarative half — the cyrilgdn/postgresql provider) ─
variable "pg_host" {
  description = "Host the postgresql provider connects to — the Citus coordinator, or localhost if you SSH-forward its port."
  type        = string

  validation {
    condition     = length(trimspace(var.pg_host)) > 0
    error_message = "pg_host must be a non-empty host/IP."
  }
}

variable "pg_port" {
  description = "TCP port of the coordinator (direct, NOT the pgbouncer pooled port)."
  type        = number
  default     = 5432
}

variable "pg_superuser" {
  description = "Superuser role the provider authenticates as (owns/creates roles + databases)."
  type        = string

  validation {
    condition     = length(trimspace(var.pg_superuser)) > 0
    error_message = "pg_superuser must be a non-empty role name."
  }
}

variable "pg_password" {
  description = "Password for pg_superuser. Source from Vault (vault-secrets) — never hard-code."
  type        = string
  sensitive   = true
}

variable "pg_connect_database" {
  description = "Database the provider connects to for administrative work (roles/db creation)."
  type        = string
  default     = "postgres"
}

variable "pg_sslmode" {
  description = "libpq sslmode for the provider connection."
  type        = string
  default     = "prefer"

  validation {
    condition     = contains(["disable", "allow", "prefer", "require", "verify-ca", "verify-full"], var.pg_sslmode)
    error_message = "pg_sslmode must be one of: disable, allow, prefer, require, verify-ca, verify-full."
  }
}

variable "pg_provider_superuser" {
  description = "Tells the provider whether pg_superuser is a real superuser (affects SET ROLE / ownership ops). true for on-prem coordinator."
  type        = bool
  default     = true
}

# ── SSH (imperative half — .sql exec, pgbouncer file write, reload, hooks) ────
variable "ssh_host" {
  description = "Host to SSH into for imperative actions (the lb host running the Citus/pgbouncer containers)."
  type        = string

  validation {
    condition     = length(trimspace(var.ssh_host)) > 0
    error_message = "ssh_host must be a non-empty host/IP."
  }
}

variable "ssh_user" {
  description = "SSH username on ssh_host (must be able to `sudo docker …`)."
  type        = string
}

variable "ssh_port" {
  description = "SSH port on ssh_host."
  type        = number
  default     = 22
}

variable "ssh_opts" {
  description = "Extra ssh(1) flags appended verbatim (e.g. `-i /path/key -o StrictHostKeyChecking=accept-new`)."
  type        = string
  default     = "-o StrictHostKeyChecking=accept-new -o BatchMode=yes"
}

variable "coordinator_container" {
  description = "Name of the Citus coordinator container on ssh_host (where .sql is executed via docker exec)."
  type        = string
  default     = "coordinator"
}

variable "pgbouncer_container" {
  description = "Name of the pgbouncer container on ssh_host (SIGHUP'd to hot-reload after a config change)."
  type        = string
  default     = "pgbouncer"
}

variable "pgbouncer_remote_dir" {
  description = "Host dir bind-mounted into pgbouncer at /etc/pgbouncer/pgbouncer.d. Terraform owns databases.ini here; Ansible owns the base pgbouncer.ini that %include's it."
  type        = string
  default     = "/opt/citus-docker/pgbouncer.d"
}

# ── Services — the desired state, grouped per APPLICATION SERVICE ─────────────
# Each key is a service (e.g. "booking-service") that owns ITS database + roles + grants + seed
# SQL. This is the primary input: every service's config reads as one self-contained block.
# Works for BOTH layouts: one file with many services here, OR folder-per-service with one entry
# per unit — same module either way.
#
# NOTE: NOT marked sensitive — it's a for_each source (Terraform forbids sensitive for_each); the
# provider still treats each role's `password` as sensitive on its own.
variable "services" {
  description = "Per-application-service bundle: each service owns a database, its roles, grants, and seed SQL."
  type = map(object({
    database = object({
      name             = optional(string) # null => the service key
      owner            = optional(string) # null => connecting superuser; usually the service's app role
      template         = optional(string, "template0")
      encoding         = optional(string, "UTF8")
      lc_collate       = optional(string, "C")
      lc_ctype         = optional(string, "C")
      connection_limit = optional(number, -1)
      extensions       = optional(list(string), []) # e.g. ["citus", "uuid-ossp"]
      schemas          = optional(list(string), [])
      sql_files        = optional(list(string), []) # paths on the RUNNER, run post-create
      pgbouncer = optional(object({
        register  = optional(bool, true)
        dbname    = optional(string)
        pool_mode = optional(string)
        pool_size = optional(number)
      }), {})
    })
    # This service's roles. KEYS are real Postgres role names and must be globally UNIQUE across
    # all services (Postgres roles are cluster-wide) — convention: "<svc>_app", "<svc>_ro".
    roles = optional(map(object({
      login       = optional(bool, true)
      password    = optional(string)
      superuser   = optional(bool, false)
      create_db   = optional(bool, false)
      create_role = optional(bool, false)
      inherit     = optional(bool, true)
      replication = optional(bool, false)
      conn_limit  = optional(number, -1)
      member_of   = optional(list(string), [])
      valid_until = optional(string)
    })), {})
    # Grants apply to THIS service's database (implicit — no need to repeat the db name).
    # on_future=true => a DEFAULT PRIVILEGE (covers objects created LATER, e.g. by the service's
    # migrations) instead of an immediate grant on existing objects. `owner` is then required: the
    # role whose future objects the privilege applies to (the app/owner role migrations run as).
    grants = optional(list(object({
      role        = string
      schema      = optional(string, "public")
      object_type = optional(string, "table")
      objects     = optional(list(string), [])
      privileges  = list(string)
      with_grant  = optional(bool, false)
      on_future   = optional(bool, false)
      owner       = optional(string) # required when on_future = true
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for svc in keys(var.services) : length(trimspace(svc)) > 0])
    error_message = "every service name (map key) must be non-empty."
  }

  # Postgres roles are cluster-global — names must be unique across ALL services.
  validation {
    condition     = length(flatten([for cfg in values(var.services) : keys(cfg.roles)])) == length(distinct(flatten([for cfg in values(var.services) : keys(cfg.roles)])))
    error_message = "role names must be UNIQUE across all services (Postgres roles are cluster-global). Prefix per service, e.g. booking_app / booking_ro."
  }

  validation {
    condition = alltrue(flatten([
      for cfg in values(var.services) : [
        for g in cfg.grants : contains(
          ["database", "schema", "table", "sequence", "function", "procedure", "routine", "foreign_data_wrapper", "foreign_server", "column", "type"],
          g.object_type
        )
      ]
    ]))
    error_message = "each grant.object_type must be a valid postgresql_grant object_type (table, sequence, schema, database, function, ...)."
  }

  validation {
    condition = alltrue(flatten([
      for cfg in values(var.services) : [for g in cfg.grants : length(g.privileges) > 0]
    ]))
    error_message = "each grant must list at least one privilege."
  }

  validation {
    condition = alltrue(flatten([
      for cfg in values(var.services) : [for g in cfg.grants : !g.on_future || (g.owner != null && length(trimspace(coalesce(g.owner, ""))) > 0)]
    ]))
    error_message = "a grant with on_future = true must set `owner` (the role whose future objects the privilege covers)."
  }

  validation {
    condition = alltrue([
      for cfg in values(var.services) :
      cfg.database.pgbouncer.pool_mode == null || contains(["session", "transaction", "statement"], cfg.database.pgbouncer.pool_mode)
    ])
    error_message = "database.pgbouncer.pool_mode must be one of: session, transaction, statement."
  }
}

# ── Arbitrary pre/post actions (run over SSH as root via bash) ────────────────
variable "pre_hooks" {
  description = "Commands run over SSH BEFORE databases are created (e.g. tablespace prep, extension-package install). Keyed by unique name."
  type = list(object({
    name    = string
    command = string
  }))
  default = []
}

variable "post_hooks" {
  description = "Commands run over SSH AFTER everything (roles/dbs/grants/sql/pgbouncer) is applied."
  type = list(object({
    name    = string
    command = string
  }))
  default = []
}

variable "tags" {
  description = "Free-form labels (recorded in outputs / passed where a provider supports them)."
  type        = map(string)
  default     = {}
}

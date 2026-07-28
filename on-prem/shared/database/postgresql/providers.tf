terraform {
  required_version = ">= 1.9"

  required_providers {
    # Declarative management of roles / databases / grants / schemas / extensions.
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
    # terraform_data (built-in, TF >= 1.4) drives the imperative side-effects
    # (.sql execution, pgbouncer file + reload, pre/post hooks) over SSH — no
    # `null`/`local` providers needed.
  }
}

# PostgreSQL provider — connects over TCP to the Citus COORDINATOR (the write entry point;
# Citus propagates CREATE ROLE / GRANT to the workers automatically). Because the runner is
# REMOTE (over SSH), give it a network route to the coordinator directly, OR open an SSH
# local-forward first and point pg_host at localhost. This block can also be moved to a
# Terragrunt `generate "provider"` if you prefer the root to own it (mirrors the commented
# provider blocks in the other shared modules).
provider "postgresql" {
  host     = var.pg_host
  port     = var.pg_port
  username = var.pg_superuser
  password = var.pg_password
  database = var.pg_connect_database
  sslmode  = var.pg_sslmode
  # `superuser=false` is required for managed/pooled endpoints that forbid SET ROLE; our
  # on-prem coordinator connects as a real superuser, so default true. Var-controlled.
  superuser       = var.pg_provider_superuser
  connect_timeout = 15
  max_connections = 4
}

output "databases" {
  description = "Names of the databases this module manages."
  value       = sort(keys(postgresql_database.this))
}

output "roles" {
  description = "Names of the roles this module manages (passwords are NOT exposed)."
  value       = sort(keys(postgresql_role.this))
}

output "schemas" {
  description = "Managed (database, schema) pairs."
  value       = { for k, v in postgresql_schema.this : k => { database = v.database, schema = v.name } }
}

output "connection_uris" {
  description = "Per-database libpq URIs (host:port from the provider connection; no credentials)."
  value = {
    for db in keys(postgresql_database.this) :
    db => "postgresql://${var.pg_host}:${var.pg_port}/${db}"
  }
}

output "pgbouncer_databases_ini" {
  description = "The exact [databases] include file Terraform wrote to the pgbouncer host (for debugging/diffing)."
  value       = length(local.pgbouncer_dbs) > 0 ? local.pgbouncer_ini : ""
}

output "tags" {
  description = "Echo of the input tags."
  value       = var.tags
}

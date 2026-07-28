# Extensions, per (database, extension). e.g. ["citus", "uuid-ossp", "pg_stat_statements"].
# For "citus" this runs CREATE EXTENSION citus in that db (still needs per-db node
# registration to actually shard — see the note in databases.tf).
resource "postgresql_extension" "this" {
  for_each = var.enabled ? local.db_extensions : {}

  name     = each.value.extension
  database = each.value.database

  # create_cascade pulls in extension deps (safe default for uuid-ossp etc.)
  create_cascade = true

  depends_on = [postgresql_database.this]
}

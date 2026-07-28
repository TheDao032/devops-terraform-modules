# Schemas, per (database, schema). Created after the database exists.
resource "postgresql_schema" "this" {
  for_each = var.enabled ? local.db_schemas : {}

  name     = each.value.schema
  database = each.value.database
  owner    = each.value.owner # the service's app role (null => connecting superuser)

  # Drop only when empty (safety).
  drop_cascade = false

  depends_on = [postgresql_database.this, postgresql_role.this]
}

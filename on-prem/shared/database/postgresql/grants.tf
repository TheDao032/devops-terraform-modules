# Privilege grants, two kinds:
#   on_future = false -> postgresql_grant on EXISTING objects (empty `objects` => all current).
#   on_future = true  -> postgresql_default_privileges for FUTURE objects the `owner` creates
#                        (the right tool when tables come from the service's migrations LATER).
# `schema` is omitted ONLY for object_type "database"; for "schema" it NAMES the schema being
# granted on (the provider requires it there — omitting it errors "schema is mandatory").

resource "postgresql_grant" "this" {
  for_each = var.enabled ? local.grants_now : {}

  role              = each.value.role
  database          = each.value.database
  schema            = each.value.object_type == "database" ? null : each.value.schema
  object_type       = each.value.object_type
  objects           = each.value.objects
  privileges        = each.value.privileges
  with_grant_option = each.value.with_grant

  depends_on = [
    postgresql_role.this,
    postgresql_schema.this,
    postgresql_database.this,
  ]
}

# Default privileges: whenever `owner` creates a new object of this type in the schema, `role`
# automatically gets these privileges — so a read-only role sees tables created by later migrations.
resource "postgresql_default_privileges" "this" {
  for_each = var.enabled ? local.grants_future : {}

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  owner       = each.value.owner
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [
    postgresql_role.this,
    postgresql_schema.this,
    postgresql_database.this,
  ]
}

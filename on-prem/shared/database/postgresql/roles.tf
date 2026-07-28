# Roles / users. Citus auto-propagates CREATE ROLE + GRANT to the workers (role
# propagation is on by default in Citus 11+), so these only need to be created on
# the coordinator. Runs after pre_hooks so any prep (tablespaces, etc.) is in place.
resource "postgresql_role" "this" {
  for_each = var.enabled ? local.roles : {}

  name             = each.key
  login            = each.value.login
  password         = each.value.password
  superuser        = each.value.superuser
  create_database  = each.value.create_db
  create_role      = each.value.create_role
  inherit          = each.value.inherit
  replication      = each.value.replication
  connection_limit = each.value.conn_limit
  roles            = each.value.member_of
  valid_until      = each.value.valid_until

  # Don't drop objects the role owns on destroy — safer for shared clusters.
  skip_drop_role = false

  depends_on = [terraform_data.pre_hooks]
}

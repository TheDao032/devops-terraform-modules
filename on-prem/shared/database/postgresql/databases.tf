# Databases. owner=null => the connecting superuser owns it. Created after the roles
# (so a named owner exists) and after pre_hooks.
#
# CITUS NOTE: a freshly-created database is NOT Citus-enabled. Add "citus" to its
# `extensions` (extensions.tf runs CREATE EXTENSION citus in the db), then register the
# workers FOR THAT DATABASE (citus_add_node runs per-database) — do that via a post_hook or
# the Ansible role. The default single `app` db is already enabled by the citus-docker role.
resource "postgresql_database" "this" {
  for_each = var.enabled ? local.databases : {}

  name              = each.key
  owner             = each.value.owner
  template          = each.value.template
  encoding          = each.value.encoding
  lc_collate        = each.value.lc_collate
  lc_ctype          = each.value.lc_ctype
  connection_limit  = each.value.connection_limit
  allow_connections = true

  depends_on = [postgresql_role.this, terraform_data.pre_hooks]
}

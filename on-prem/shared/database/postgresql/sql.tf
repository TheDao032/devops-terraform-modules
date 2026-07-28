# Seed / migration .sql, per (database, file). The file lives on the RUNNER (tenant data,
# supplied by Terragrunt); we stream it over SSH into `psql -f -` inside the coordinator
# container. Idempotency is the SQL author's job (CREATE ... IF NOT EXISTS, etc.); the
# resource re-runs whenever the file's content hash changes.
#
# Runs LAST of the declarative-adjacent steps: after db + schema + extension + grants.
resource "terraform_data" "sql" {
  for_each = var.enabled ? local.sql_units : {}

  triggers_replace = {
    sha  = filesha256(each.value.path)
    db   = each.value.database
    host = var.ssh_host
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      cat ${each.value.path} | ${local.ssh} \
        'sudo docker exec -i ${var.coordinator_container} psql -v ON_ERROR_STOP=1 -U ${var.pg_superuser} -d ${each.value.database}'
    EOT
  }

  depends_on = [
    postgresql_database.this,
    postgresql_schema.this,
    postgresql_extension.this,
    postgresql_grant.this,
  ]
}

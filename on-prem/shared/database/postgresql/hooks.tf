# Arbitrary pre/post actions over SSH. The command is base64-encoded on the runner and
# decoded+executed with `bash` as root on the host — so it survives ANY quoting/special
# characters (newlines, quotes, $), unlike inlining the raw string into the ssh argument.

# BEFORE databases are created. roles.tf and databases.tf depend_on this.
resource "terraform_data" "pre_hooks" {
  for_each = var.enabled ? { for h in var.pre_hooks : h.name => h } : {}

  triggers_replace = { cmd = each.value.command, host = var.ssh_host }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      echo '${base64encode(each.value.command)}' | ${local.ssh} 'base64 -d | sudo bash -s'
    EOT
  }
}

# AFTER everything (roles/dbs/grants/sql/pgbouncer) is applied.
resource "terraform_data" "post_hooks" {
  for_each = var.enabled ? { for h in var.post_hooks : h.name => h } : {}

  triggers_replace = { cmd = each.value.command, host = var.ssh_host }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      echo '${base64encode(each.value.command)}' | ${local.ssh} 'base64 -d | sudo bash -s'
    EOT
  }

  depends_on = [
    postgresql_grant.this,
    terraform_data.sql,
    terraform_data.pgbouncer,
  ]
}

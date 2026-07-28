# pgbouncer registration. ONE combined file that Terraform fully owns and regenerates from
# the whole databases{} map — because pgbouncer's `%include` takes a single filename (no glob).
# The Ansible-owned base pgbouncer.ini `%include`s this file exactly once (static line);
# Terraform never touches the base. After writing, SIGHUP hot-reloads pgbouncer (no restart,
# no dropped connections) — the pgbouncer image has no psql, so we signal rather than `RELOAD;`.
#
# Content is base64'd on the runner and decoded on the host: survives any special characters.
resource "terraform_data" "pgbouncer" {
  count = var.enabled && length(local.pgbouncer_dbs) > 0 ? 1 : 0

  triggers_replace = {
    content = local.pgbouncer_ini
    host    = var.ssh_host
    dir     = var.pgbouncer_remote_dir
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      echo '${base64encode(local.pgbouncer_ini)}' | ${local.ssh} \
        'base64 -d | sudo tee ${var.pgbouncer_remote_dir}/databases.ini >/dev/null && sudo docker kill --signal=HUP ${var.pgbouncer_container}'
    EOT
  }

  depends_on = [postgresql_database.this]
}

locals {
  policies_tmp_file = "${path.module}/templates/policies/policies.hcl.tftpl"
}

# ── Authorization ─────────────────────────────────────────────────────────────
# Policies are the shared authZ layer — every auth method (approle in roles.tf, userpass in
# users.tf) attaches these by name. One policy per entry in var.roles, rendered from the
# shared template (same output as the vault-roles module).
resource "vault_policy" "main" {
  for_each = var.roles
  name     = each.key
  policy = fileexists(local.policies_tmp_file) ? templatefile(local.policies_tmp_file, {
    environment = var.environment
    policies    = each.value
  }) : ""
}

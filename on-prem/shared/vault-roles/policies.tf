locals {
  policies_tmp_file = "${path.module}/templates/policies/policies.hcl.tmpl"
}

resource "vault_policy" "main" {
  for_each = var.roles
  name     = each.key
  policy = fileexists(local.policies_tmp_file) ? templatefile(local.policies_tmp_file, {
    environment = var.environment
    policies    = each.value
  }) : ""
}

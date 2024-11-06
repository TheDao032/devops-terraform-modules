locals {
  # Extracts entries where the value contains `_RANDOM_`
  database_secrets_parameters = {
    for path, creds in var.database : path => {
      for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_")
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  # Generate resolved secrets from random_password
  database_secrets_resolve_parameters = {
    for path, creds in local.database_secrets_parameters : path => {
      for k, v in creds : k => random_password.database_secrets["${path}_${k}"].result
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  # Merge original `database` values with generated passwords
  database_secrets = {
    for path, creds in var.database : path => merge(
      creds,
      lookup(local.database_secrets_resolve_parameters, path, {})
    )
  }

}

resource "random_password" "database_secrets" {
  for_each         = { for path, creds in local.database_secrets_parameters : "${path}_${keys(creds)[0]}" => creds }
  length           = regex("[0-9]+", each.value[keys(each.value)[0]])
  override_special = "!()-_=+"

  lifecycle {
    ignore_changes = [override_special]
  }
}

resource "vault_generic_secret" "database_secrets" {
  for_each = local.database_secrets
  path = "${vault_mount.kv.path}/${each.key}"

  data_json = jsonencode(
    each.value
  )

  depends_on = [ vault_mount.kv ]
}

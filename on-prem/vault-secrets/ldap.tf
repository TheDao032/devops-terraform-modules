locals {
  # Extracts entries where the value contains `_RANDOM_`
  ldap_secrets_parameters = {
    for path, creds in var.ldap : path => {
      for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_")
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  flattened_ldap_secrets_parameters = flatten([
    for path, creds in local.ldap_secrets_parameters : [
      for key, value in creds : {
        path  = path
        key   = key
        value = value
      }
    ]
  ])

  # Generate resolved secrets from random_password
  ldap_secrets_resolve_parameters = {
    for path, creds in local.ldap_secrets_parameters : path => {
      for k, v in creds : k => random_password.ldap_secrets["${path}_${k}"].result
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  # Merge original `ldap` values with generated passwords
  ldap_secrets = {
    for path, creds in var.ldap : path => merge(
      creds,
      lookup(local.ldap_secrets_resolve_parameters, path, {})
    )
  }

}

# resource "random_password" "ldap_secrets" {
#   for_each         = { for path, creds in local.ldap_secrets_parameters : "${path}_${keys(creds)[0]}" => creds }
#   length           = regex("[0-9]+", each.value[keys(each.value)[0]])
#   override_special = "!()-_=+"
#
#   lifecycle {
#     ignore_changes = [override_special]
#   }
# }

resource "random_password" "ldap_secrets" {
  for_each = {
    for secret in local.flattened_ldap_secrets_parameters :
    "${secret.path}_${secret.key}" => secret
  }

  length           = regex("[0-9]+", each.value.value)
  override_special = "!()-_=+"

  lifecycle {
    ignore_changes = [override_special]
  }
}

resource "vault_generic_secret" "ldap_secrets" {
  for_each = local.ldap_secrets
  path     = "${vault_mount.kv.path}/${each.key}"

  data_json = jsonencode(
    each.value
  )

  depends_on = [vault_mount.kv]
}

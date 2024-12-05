locals {
  # Extracts entries where the value contains `_RANDOM_`
  keycloak_secrets_parameters = {
    for path, creds in var.keycloak : path => {
      for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_")
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  flattened_keycloak_secrets_parameters = flatten([
    for path, creds in local.grafana_secrets_parameters : [
      for key, value in creds : {
        path  = path
        key   = key
        value = value
      }
    ]
  ])

  # Generate resolved secrets from random_password
  keycloak_secrets_resolve_parameters = {
    for path, creds in local.keycloak_secrets_parameters : path => {
      for k, v in creds : k => random_password.keycloak_secrets["${path}_${k}"].result
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  # Merge original `keycloak` values with generated passwords
  keycloak_secrets = {
    for path, creds in var.keycloak : path => merge(
      creds,
      lookup(local.keycloak_secrets_resolve_parameters, path, {})
    )
  }

}

# resource "random_password" "keycloak_secrets" {
#   for_each         = { for path, creds in local.keycloak_secrets_parameters : "${path}_${keys(creds)[0]}" => creds }
#   length           = regex("[0-9]+", each.value[keys(each.value)[0]])
#   override_special = "!()-_=+"
#
#   lifecycle {
#     ignore_changes = [override_special]
#   }
# }

resource "random_password" "keycloak_secrets" {
  for_each = {
    for secret in local.flattened_keycloak_secrets_parameters :
    "${secret.path}_${secret.key}" => secret
  }

  length           = regex("[0-9]+", each.value.value)
  override_special = "!()-_=+"

  lifecycle {
    ignore_changes = [override_special]
  }
}

resource "vault_generic_secret" "keycloak_secrets" {
  for_each = local.keycloak_secrets
  path     = "${vault_mount.kv.path}/${each.key}"

  data_json = jsonencode(
    each.value
  )

  depends_on = [vault_mount.kv]
}

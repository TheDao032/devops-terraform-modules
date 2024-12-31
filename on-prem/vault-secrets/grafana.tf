locals {
  # Extracts entries where the value contains `_RANDOM_`
  grafana_secrets_parameters = {
    for path, creds in var.grafana : path => {
      for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_")
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  flattened_grafana_secrets_parameters = flatten([
    for path, creds in local.grafana_secrets_parameters : [
      for key, value in creds : {
        path  = path
        key   = key
        value = value
      }
    ]
  ])

  # Generate resolved secrets from random_password
  grafana_secrets_resolve_parameters = {
    for path, creds in local.grafana_secrets_parameters : path => {
      for k, v in creds : k => random_password.grafana_secrets["${path}_${k}"].result
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  # Merge original `grafana` values with generated passwords
  grafana_secrets = {
    for path, creds in var.grafana : path => merge(
      creds,
      lookup(local.grafana_secrets_resolve_parameters, path, {})
    )
  }

}

# resource "random_password" "grafana_secrets" {
#   for_each         = { for path, creds in local.grafana_secrets_parameters : "${path}_${keys(creds)[0]}" => creds }
#   length           = regex("[0-9]+", each.value[keys(each.value)[0]])
#   override_special = "!()-_=+"
#
#   lifecycle {
#     ignore_changes = [override_special]
#   }
# }

resource "random_password" "grafana_secrets" {
  for_each = {
    for secret in local.flattened_grafana_secrets_parameters :
    "${secret.path}_${secret.key}" => secret
  }

  length           = regex("[0-9]+", each.value.value)
  override_special = "!()-_=+"

  lifecycle {
    ignore_changes = [override_special]
  }
}

resource "vault_kv_secret_v2" "grafana_secrets" {
  for_each     = local.grafana_secrets
  name         = each.key
  mount        = vault_mount.kv.path
  disable_read = true

  data_json = jsonencode(
    each.value
  )
}

# resource "vault_generic_secret" "grafana_secrets" {
#   for_each = local.grafana_secrets
#   path     = "${vault_mount.kv.path}/${each.key}"
#
#   data_json = jsonencode(
#     each.value
#   )
#
#   depends_on = [vault_mount.kv]
# }

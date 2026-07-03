locals {
  # Extracts entries where the value contains `_RANDOM_`
  secrets_parameters = {
    for path, creds in var.secrets : path => {
      for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_")
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  flattened_secrets_parameters = flatten([
    for path, creds in local.secrets_parameters : [
      for key, value in creds : {
        path  = path
        key   = key
        value = value
      }
    ]
  ])

  # Generate resolved secrets from random_password
  secrets_resolve_parameters = {
    for path, creds in local.secrets_parameters : path => {
      for k, v in creds : k => random_password.secrets["${path}_${k}"].result
    } if length({ for k, v in creds : k => v if contains(split(" ", v), "_RANDOM_") }) > 0
  }

  # Merge original `secrets` values with generated passwords
  secrets = {
    for path, creds in var.secrets : path => merge(
      creds,
      lookup(local.secrets_resolve_parameters, path, {})
    )
  }

}

resource "vault_mount" "kv" {
  path = var.environment
  type = "kv"
  options = {
    version = "2"
  }
  description = "KV Version 2 secret engine mount"
}

resource "random_password" "secrets" {
  for_each = {
    for secret in local.flattened_secrets_parameters :
    "${secret.path}_${secret.key}" => secret
  }

  length           = regex("[0-9]+", each.value.value)
  override_special = "!()-_=+"

  lifecycle {
    ignore_changes = [override_special]
  }
}

resource "vault_kv_secret_v2" "secrets" {
  for_each     = local.secrets
  name         = each.key
  mount        = vault_mount.kv.path
  disable_read = true

  data_json = jsonencode(
    each.value
  )
}

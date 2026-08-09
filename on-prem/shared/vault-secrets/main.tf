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

  # Stable hashed siblings (e.g. bcrypt for ArgoCD's argocdServerAdminPassword). random_password
  # exposes .bcrypt_hash — computed ONCE with the password and stored in state, so it's stable (no
  # bcrypt() re-salt churn). sha*/md5 are deterministic. Sibling key = "<key>_<algo>".
  password_hash_siblings = {
    for path, h in var.password_hashes :
    path => {
      "${h.key}_${h.algo}" = (
        h.algo == "bcrypt" ? random_password.secrets["${path}_${h.key}"].bcrypt_hash :
        h.algo == "sha256" ? sha256(random_password.secrets["${path}_${h.key}"].result) :
        h.algo == "sha512" ? sha512(random_password.secrets["${path}_${h.key}"].result) :
        h.algo == "sha1" ? sha1(random_password.secrets["${path}_${h.key}"].result) :
        md5(random_password.secrets["${path}_${h.key}"].result)
      )
    }
    if contains(keys(local.secrets_parameters), path)
  }

  # Merge original `secrets` values with generated passwords + any hashed siblings
  secrets_stage1 = {
    for path, creds in var.secrets : path => merge(
      creds,
      lookup(local.secrets_resolve_parameters, path, {}),
      lookup(local.password_hash_siblings, path, {}),
    )
  }

  # Composition pass — substitute a single `{{<path>:<key>}}` reference token in any STRING value
  # with the RESOLVED value of that other secret (post-random). Lets e.g. a DB connection string
  # embed a generated password WITHOUT the password ever being its own readable key, and keeps the
  # DSN inside the app's own subtree (so the app's least-privilege Vault role can read it).
  #
  # Additive + backward-compatible: a value with no `{{...}}` token passes through unchanged, so
  # existing tenants (bosch/renesas) are untouched. Values stay strings → the per-path `map(any)`
  # element type stays uniform (mixing an object value in would break Terraform type unification).
  # ONE token per value (sufficient for DSNs). Example (env.hcl):
  #   DATABASE_WRITE_DB_CONNECTION_STRING =
  #     "postgresql://user:{{database/trainee/app/creds:password}}@host:5432/db?sslmode=disable"
  secrets = {
    for path, creds in local.secrets_stage1 : path => {
      for k, v in creds : k => (
        can(regex("\\{\\{[^}]+\\}\\}", v))
        ? replace(
          v,
          regex("\\{\\{[^}]+\\}\\}", v), # the literal token, incl. braces (no capture group → whole match)
          local.secrets_stage1[
            split(":", regex("\\{\\{([^}]+)\\}\\}", v)[0])[0] # ref path (regex 1-group → tuple; [0]=inner "path:key", then split)
            ][
            split(":", regex("\\{\\{([^}]+)\\}\\}", v)[0])[1] # ref key
          ]
        )
        : v
      )
    }
  }

}

# resource "vault_mount" "kv" {
#   path = var.environment
#   type = "kv"
#   options = {
#     version = "2"
#   }
#   description = "KV Version 2 secret engine mount"
# }

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
  name         = "${var.path_prefix}${each.key}"
  mount        = var.kv_mount_path
  disable_read = true

  data_json = jsonencode(
    each.value
  )
}

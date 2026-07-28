locals {
  approle_secret_tmp_file = "${path.module}/namespaces/${var.namespace}/approle-secret.yml.tftpl"
  approle_secret_created  = fileexists(local.approle_secret_tmp_file) ? var.enabled : var.disabled

  secret_store_tmp_file = "${path.module}/namespaces/${var.namespace}/secret-store.yml.tftpl"
  secret_store_created  = fileexists(local.secret_store_tmp_file) ? var.enabled : var.disabled

  # KV mount path the SecretStore reads FROM = the ORG mount ("fitmate"), matching vault-auths's
  # engine mount. The env folder ("local/") lives INSIDE the mount and is part of each
  # ExternalSecret's remoteRef.key (downstream), not the SecretStore path.
  kv_path = trimspace(var.org) != "" ? var.org : var.environment
}

resource "kubectl_manifest" "approle_secret" {
  count = local.approle_secret_created
  yaml_body = templatefile(local.approle_secret_tmp_file,
    {
      namespace  = var.namespace
      parameters = var.parameters
    }
  )

  server_side_apply = true
}

resource "kubectl_manifest" "secret_store" {
  count = local.secret_store_created
  yaml_body = templatefile(local.secret_store_tmp_file,
    {
      namespace  = var.namespace
      mount_path = local.kv_path
      parameters = var.parameters
    }
  )

  server_side_apply = true
  depends_on        = [kubectl_manifest.approle_secret] # Secret must exist before the store references it
}

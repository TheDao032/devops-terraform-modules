locals {
  value_file         = "${path.module}/values.yml.tmpl"
  sc_value_file      = "${path.module}/sc.yml.tmpl"
  storage_class_name = "vault-sc"
}

resource "kubectl_manifest" "storage_class" {
  yaml_body = templatefile(local.sc_value_file, {
    storage_class_name = local.storage_class_name
    namespace = var.namespace
  })
}

resource "helm_release" "main" {
  name             = var.helm_release_name
  namespace        = var.namespace
  repository       = var.helm_repository
  version          = var.chart_version
  chart            = var.helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.value_file) ?
    [
      templatefile(
        local.value_file,
        {
          storage_class_name: local.storage_class_name
          vault_hosts: var.vault_hosts
          server_conf: var.server_conf
          injector_conf: var.injector_conf
          ui_conf: var.ui_conf
          vault_tls_server_name: var.vault_tls_server_name
          vault_tls_ca_name: var.vault_tls_ca_name
          vault_server_url: var.vault_server_url
          vault_server_token: var.vault_server_token
          consul_server_url: var.consul_server_url
        }
      )
  ] : null)

  depends_on = [kubectl_manifest.storage_class]
}

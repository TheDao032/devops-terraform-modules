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
          storage_class_name: local.storage_class_name,
          vault_hosts: var.vault_hosts,
          server_conf: var.server_conf,
          ui_conf: var.ui_conf,
        }
      )
  ] : null)

  depends_on = [kubectl_manifest.storage_class]
}

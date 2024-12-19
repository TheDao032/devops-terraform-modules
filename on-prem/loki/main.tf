locals {
  loki_value_file         = "${path.module}/templates/values/values.loki.monolithic.yml.tftpl"
  alloy_value_file        = "${path.module}/templates/values/values.alloy.yml.tftpl"
  loki_sc_value_file      = "${path.module}/templates/storage-classes/sc.loki.yml.tftpl"
  loki_storage_class_name = "loki-sc"
}

resource "kubectl_manifest" "loki_storage_class" {
  yaml_body = templatefile(local.loki_sc_value_file, {
    storage_class_name = local.loki_storage_class_name
    namespace          = var.namespace
  })
}

resource "helm_release" "loki" {
  name             = var.loki_helm_release_name
  namespace        = var.namespace
  repository       = var.helm_repository
  version          = var.loki_chart_version
  chart            = var.loki_helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.loki_value_file) ?
    [
      templatefile(
        local.loki_value_file,
        {
          loki_conf     = var.loki_conf
          storage_class = local.loki_storage_class_name
        }
      )
  ] : null)

  depends_on = [kubectl_manifest.loki_storage_class]
}

resource "helm_release" "alloy" {
  name             = var.alloy_helm_release_name
  namespace        = var.namespace
  repository       = var.helm_repository
  version          = var.alloy_chart_version
  chart            = var.alloy_helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.alloy_value_file) ?
    [
      templatefile(
        local.alloy_value_file,
        {
          alloy_conf = var.alloy_conf
        }
      )
  ] : null)

  # depends_on = [kubectl_manifest.storage_class]
}

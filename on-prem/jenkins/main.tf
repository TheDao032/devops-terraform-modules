locals {
  value_file         = "${path.module}/values.yml.tmpl"
  sc_value_file      = "${path.module}/sc.yml.tmpl"
  storage_class_name = "jenkins-sc"
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
        merge(
          var.parameters,
          {
            jenkins_version    = var.image_tag,
            jenkins_plugins    = var.jenkins_plugins
            storage_class_name = local.storage_class_name
          },
        )
      )
  ] : null)

  depends_on = [kubectl_manifest.storage_class]
}

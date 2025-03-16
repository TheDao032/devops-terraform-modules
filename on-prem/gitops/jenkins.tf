locals {
  value_file         = "${path.module}/jenkins/templates/values/values.yml.tmpl"
  sc_value_file      = "${path.module}/jenkins/templates/storage-classes/sc.yml.tmpl"
  storage_class_name = "jenkins-sc"

  chart_info = var.jenkins_conf.chart_info
}

resource "kubectl_manifest" "storage_class" {
  yaml_body = templatefile(local.sc_value_file, {
    storage_class_name = local.storage_class_name
    namespace          = var.namespace
  })
}

resource "helm_release" "main" {
  name             = local.chart_info.helm_release_name
  namespace        = local.chart_info.namespace
  repository       = local.chart_info.helm_repository
  version          = local.chart_info.chart_version
  chart            = local.chart_info.helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.value_file) ?
    [
      templatefile(
        local.value_file,
        merge(
          var.jenkins_conf.parameters,
          {
            jenkins_version    = local.chart_info.image_tag,
            jenkins_plugins    = var.jenkins_conf.plugins
            storage_class_name = local.storage_class_name
          },
        )
      )
  ] : null)

  depends_on = [kubectl_manifest.storage_class]
}

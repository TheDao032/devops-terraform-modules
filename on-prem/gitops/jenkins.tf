locals {
  jenkins_value_file = "${path.module}/jenkins/templates/values/values.yml.tmpl"
  jenkins_sc_file    = "${path.module}/jenkins/templates/storage-classes/sc.yml.tmpl"
  jenkins_sc_name    = "jenkins-sc"

  jenkins_chart = var.jenkins_conf.chart_info
}

resource "kubectl_manifest" "jenkins_sc" {
  yaml_body = templatefile(local.jenkins_sc_file, {
    storage_class_name = local.jenkins_sc_name
    namespace          = local.chart_info.namespace
  })
}

resource "helm_release" "jenkins" {
  name             = local.jenkins_chart.helm_release_name
  namespace        = local.jenkins_chart.namespace
  repository       = local.jenkins_chart.helm_repository
  version          = local.jenkins_chart.chart_version
  chart            = local.jenkins_chart.helm_release_chart
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.jenkins_value_file) ?
    [
      templatefile(
        local.jenkins_value_file,
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

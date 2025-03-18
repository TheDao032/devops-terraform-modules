locals {
  value_file = "${path.module}/charts/${var.name}/values.yml.tftpl"
  chart      = var.chart == null ? null : "${path.module}/charts/${var.name}"

  # serviceaccount_file = "${path.module}/charts/${var.name}/serviceaccount.json"
  # iam_role_created    = fileexists(local.serviceaccount_file) ? var.enabled : 0

  middle_file      = "${path.module}/charts/${var.name}/templates/traefik/middle.yml.tftpl"
  ingroute_file    = "${path.module}/charts/${var.name}/templates/traefik/ingroute.yml.tftpl"
  middle_created   = length(var.parameters.middleware_strip_prefix_list) > 0 ? length(var.parameters.middleware_strip_prefix_list) : 0
  ingroute_created = length(var.parameters.ingressroute_list) > 0 ? length(var.parameters.ingressroute_list) : 0
}

resource "helm_release" "main" {
  count            = var.enabled
  name             = var.name
  repository       = var.repository
  version          = var.chart_version
  namespace        = var.namespace
  chart            = coalesce(local.chart, var.name)
  create_namespace = true
  upgrade_install  = true
  values = (fileexists(local.value_file) ?
    [
      templatefile(
        local.value_file,
        {
          parameters = var.parameters
        },
      )
  ] : null)
}

resource "kubectl_manifest" "middle_strip_prefix" {
  count = local.middle_created

  yaml_body = templatefile(local.middle_file,
    {
      name      = var.parameters.middleware_strip_prefix_list[count.index].name
      prefixes  = var.parameters.middleware_strip_prefix_list[count.index].prefixes
      namespace = var.parameters.middleware_strip_prefix_list[count.index].namespace
    }
  )

  depends_on = [helm_release.main]
}

resource "kubectl_manifest" "ingress_route" {
  count = local.ingroute_created
  yaml_body = templatefile(local.ingroute_file,
    {
      ingress_route_name     = var.parameters.ingressroute_list[count.index].ingress_route_name
      middleware_annotations = var.parameters.ingressroute_list[count.index].middleware_annotations
      match_condition        = var.parameters.ingressroute_list[count.index].match_condition
      middlewares            = var.parameters.ingressroute_list[count.index].middlewares
      services               = var.parameters.ingressroute_list[count.index].services
      namespace              = var.parameters.ingressroute_list[count.index].namespace
    }
  )

  depends_on = [
    kubectl_manifest.traefik_middle_strip_prefix,
  ]
}

locals {
  value_file = "${path.module}/charts/${var.name}/values.yml.tftpl"
  chart      = var.chart == null ? null : "${path.module}/charts/${var.name}"

  # serviceaccount_file = "${path.module}/charts/${var.name}/serviceaccount.json"
  # iam_role_created    = fileexists(local.serviceaccount_file) ? var.enabled : 0

  middle_file      = "${path.module}/charts/${var.name}/templates/traefik/middle.yml.tftpl"
  ingroute_file    = "${path.module}/charts/${var.name}/templates/traefik/ingroute.yml.tftpl"
  middle_created   = length(var.parameters.middleware_strip_prefix_list) > 0 ? length(var.parameters.middleware_strip_prefix_list) : 0
  ingroute_created = length(var.parameters.ingressroute_list) > 0 ? length(var.parameters.ingressroute_list) : 0

  middleware_strip_prefixes = var.parameters.routes.middleware_strip_prefix_list
  ingressroutes             = var.parameters.routes.ingressroute_list
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
      name      = local.middleware_strip_prefixes[count.index].name
      prefixes  = local.middleware_strip_prefixes[count.index].prefixes
      namespace = local.middleware_strip_prefixes[count.index].namespace
    }
  )

  depends_on = [helm_release.main]
}

resource "kubectl_manifest" "ingress_route" {
  count = local.ingroute_created
  yaml_body = templatefile(local.ingroute_file,
    {
      ingress_route_name     = local.ingressroutes[count.index].ingress_route_name
      middleware_annotations = local.ingressroutes[count.index].middleware_annotations
      match_condition        = local.ingressroutes[count.index].match_condition
      middlewares            = local.ingressroutes[count.index].middlewares
      services               = local.ingressroutes[count.index].services
      namespace              = local.ingressroutes[count.index].namespace
    }
  )

  depends_on = [
    kubectl_manifest.middle_strip_prefix,
  ]
}

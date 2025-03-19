locals {
  router                    = var.parameters.router
  middleware_strip_prefixes = local.router != {} && try(var.parameters.router.middleware_strip_prefixes, []) ? var.parameters.router.middleware_strip_prefixes : []
  ingressroutes             = local.router != {} && try(var.parameters.router.ingressroutes, []) ? var.parameters.router.ingressroutes : []

  middle_file      = "${path.module}/${var.route_type}/middle.yml.tftpl"
  ingroute_file    = "${path.module}/${var.route_type}/ingroute.yml.tftpl"
  middle_created   = length(local.middleware_strip_prefixes) > 0 ? length(local.middleware_strip_prefixes) : 0
  ingroute_created = length(local.ingressroutes) > 0 ? length(local.ingressroutes) : 0
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

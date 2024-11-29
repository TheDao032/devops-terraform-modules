locals {
  value_file            = "${path.module}/values.yml.tftpl"
  traefik_ingroute_file = "${path.module}/templates/ings/traefik_ingroute.yml.tftpl"
  traefik_middle_file   = "${path.module}/templates/middlewares/traefik_middle.yml.tftpl"
  traefik_namespace     = "kube-system"

  middleware_list = {
    keycloak = {
      name = var.keycloak.ingress.strip_prefix
      prefixes = [
        "/"
      ]
      namespace = var.namespace
    }
  }

  ingressroute_list = {
    keycloak = {
      ingress_route_name     = "keycloak-ingressroute"
      middleware_annotations = "${var.namespace}-${var.keycloak.ingress.strip_prefix}@kubernetescrd"
      match_condition        = "Host(`${var.keycloak_host}`)"
      middlewares = [
        {
          name      = var.keycloak.ingress.strip_prefix
          namespace = var.namespace
        }
      ]
      services = [
        {
          name      = "${var.helm_release_name}-keycloak"
          port      = 80
          namespace = var.namespace
        }
      ]
      namespace = var.namespace
    }
  }
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
          keycloak_host = var.keycloak_host
        },
      )
  ] : null)
}

resource "kubectl_manifest" "traefik_middle" {
  for_each = local.middleware_list

  yaml_body = templatefile(local.traefik_middle_file,
    {
      name      = each.value.name
      prefixes  = each.value.prefixes
      namespace = each.value.namespace
    }
  )

  depends_on = [helm_release.main]
}

resource "kubectl_manifest" "traefik_ingressroute" {
  for_each = local.ingressroute_list
  yaml_body = templatefile(local.traefik_ingroute_file,
    {
      ingress_route_name     = each.value.ingress_route_name
      middleware_annotations = each.value.middleware_annotations
      match_condition        = each.value.match_condition
      middlewares            = each.value.middlewares
      services               = each.value.services
      namespace              = each.value.namespace
    }
  )

  depends_on = [kubectl_manifest.traefik_middle]
}

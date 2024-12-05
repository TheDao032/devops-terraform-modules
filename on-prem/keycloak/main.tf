locals {
  value_file            = "${path.module}/values.yml.tftpl"
  sc_value_file         = "${path.module}/sc.yml.tftpl"
  traefik_ingroute_file = "${path.module}/templates/ings/traefik_ingroute.yml.tftpl"
  traefik_middle_file   = "${path.module}/templates/middlewares/traefik_middle.yml.tftpl"
  traefik_namespace     = "kube-system"

  keycloak_middlewares = [
    {
      name      = var.keycloak_conf.ingress.strip_prefix
      namespace = var.namespace
    },
    # {
    #   name      = var.keycloak_conf.admin_ingress.strip_prefix
    #   namespace = var.namespace
    # }
  ]

  middleware_list = {
    keycloak = {
      name = var.keycloak_conf.ingress.strip_prefix
      prefixes = [
        "/keycloak"
      ]
      namespace = var.namespace
    }

    # keycloak_admin = {
    #   name = var.keycloak_conf.admin_ingress.strip_prefix
    #   prefixes = [
    #     "/"
    #   ]
    #   namespace = var.namespace
    # }
  }

  ingressroute_list = {
    keycloak = {
      ingress_route_name = "keycloak-ingressroute"
      match_condition    = "Host(`${var.keycloak_host}`) && PathPrefix(`${var.keycloak_conf.ingress.prefix}`)"
      middlewares = [
        {
          name      = var.keycloak_conf.ingress.strip_prefix
          namespace = var.namespace
        }
      ]
      services = [
        {
          name      = var.helm_release_name
          port      = 80
          namespace = var.namespace
        }
      ]
      # middleware_annotations = "${var.namespace}-${var.keycloak_conf.ingress.strip_prefix}@kubernetescrd"
      middleware_annotations = join(", ", [for middleware in local.keycloak_middlewares : "${var.namespace}-${middleware.name}@kubernetescrd"])
      namespace              = var.namespace
    }

    # admin_keycloak = {
    #   ingress_route_name = "keycloak-admin-ingressroute"
    #   match_condition    = "Host(`${var.keycloak_host}`)"
    #   middlewares        = local.keycloak_middlewares
    #   services = [
    #     {
    #       name      = var.helm_release_name
    #       port      = 80
    #       namespace = var.namespace
    #     }
    #   ]
    #   # middleware_annotations = "${var.namespace}-${var.keycloak_conf.admin_ingress.strip_prefix}@kubernetescrd"
    #   middleware_annotations = join(", ", [for middleware in local.keycloak_middlewares : "${var.namespace}-${middleware.name}@kubernetescrd"])
    #   namespace              = var.namespace
    # }
  }
}

resource "kubectl_manifest" "storage_class" {
  yaml_body = templatefile(local.sc_value_file, {
    storage_class_name = var.keycloak_conf.storage.class_name
    namespace          = var.namespace
  })
}

resource "helm_release" "main" {
  name             = var.helm_release_name
  namespace        = var.namespace
  repository       = var.helm_repository
  version          = var.chart_version
  chart            = var.helm_release_chart
  create_namespace = true

  values = (fileexists(local.value_file) ?
    [
      templatefile(
        local.value_file,
        {
          keycloak      = var.keycloak_conf
          namespace     = var.namespace
          keycloak_host = var.keycloak_host
        },
      )
  ] : null)

  depends_on = [kubectl_manifest.storage_class]
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

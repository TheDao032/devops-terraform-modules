locals {
  cert_manager_value_file = "${path.module}/templates/values.yml.tmpl"
  letsencrypt_value_file = "${path.module}/templates/letsencrypt.yml.tmpl"
  issuer_name = "letsencrypt-staging"
  cert_manager_secrets = "letsencrypt-staging"
}

resource "helm_release" "cert_manager" {
  name             = var.helm_release_name
  namespace        = var.namespace
  repository       = var.helm_repository
  version          = var.chart_version
  chart            = var.helm_release_chart
  create_namespace = true
  upgrade_install  = true

  values = (fileexists(local.cert_manager_value_file) ?
    [
      templatefile(
        local.cert_manager_value_file, {},
      )
  ] : null)
}

resource "kubectl_manifest" "lets_encrypt" {
  yaml_body = templatefile(
    local.letsencrypt_value_file,
    {
      issuer_name = local.issuer_name
      cert_manager_secrets = local.cert_manager_secrets
      namespace = var.namespace
      email = var.email
    }
  )

  depends_on = [ helm_release.cert_manager ]
}


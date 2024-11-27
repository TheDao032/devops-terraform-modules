locals {
  cert_manager_value_file       = "${path.module}/templates/values.yml.tftpl"
  letsencrypt_value_file        = "${path.module}/templates/letsencrypt.yml.tftpl"
  cloudflare_secret_value_file  = "${path.module}/templates/cloudflare-secret.yml.tftpl"
  certificate_secret_value_file = "${path.module}/templates/certificate.yml.tftpl"
  issuer_name                   = "letsencrypt-staging"
  cert_manager_secrets          = "letsencrypt-staging"
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

resource "kubectl_manifest" "cloudflare_secrets" {
  yaml_body = templatefile(
    local.cloudflare_secret_value_file,
    {
      cloudflare_secret_name = var.cloudflare_secret_name
      cloudflare_api_token   = var.cloudflare_api_token
      namespace              = var.namespace
    }
  )
}

resource "kubectl_manifest" "letsencrypt" {
  yaml_body = templatefile(
    local.letsencrypt_value_file,
    {
      issuer_name            = local.issuer_name
      cert_manager_secrets   = local.cert_manager_secrets
      cloudflare_secret_name = var.cloudflare_secret_name
      namespace              = var.namespace
      email                  = var.email
    }
  )

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "certificate" {
  yaml_body = templatefile(
    local.certificate_secret_value_file,
    {
      issuer_name = local.issuer_name
    }
  )

  depends_on = [helm_release.cert_manager]
}

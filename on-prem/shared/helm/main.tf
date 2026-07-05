locals {
  value_file = var.values_type == null ? "${path.module}/charts/${var.name}/values.yml.tftpl" : "${path.module}/charts/${var.name}/values.${var.values_type}.yml.tftpl"
  chart      = var.chart == null ? null : "${path.module}/charts/${var.name}"

  sc_value_file = "${path.module}/charts/${var.name}/sc.yml.tftpl"
  sc_created    = fileexists(local.sc_value_file) ? var.enabled : 0

  # Pre-helm TLS material (e.g. cert-manager Issuer/Certificate chain for Vault).
  # Split the multi-doc template into individual manifests so kubectl_manifest (one
  # doc per resource) can apply each. fileexists-gated: no-op for charts without it.
  # Applied BEFORE helm_release so the referenced Secret exists at pod start.
  tls_value_file = "${path.module}/charts/${var.name}/tls.yml.tftpl"
  tls_docs = fileexists(local.tls_value_file) && var.enabled == 1 ? [
    for doc in split("\n---\n", templatefile(local.tls_value_file, {
      parameters  = var.parameters
      namespace   = var.namespace
      environment = var.environment
    })) : trimspace(doc) if trimspace(doc) != ""
  ] : []

  # The target namespace must exist BEFORE the namespaced pre-helm manifests (tls)
  # apply — helm_release's create_namespace only runs afterwards. Gate on tls presence
  # so charts that deploy into an existing ns (e.g. kube-system) are unaffected.
  ns_created = fileexists(local.tls_value_file) ? var.enabled : 0

  # secret_store_value_file = "${path.module}/charts/${var.name}/secret-store.yml.tftpl"
  # secret_store_created    = fileexists(local.secret_store_value_file) ? var.enabled : 0
  #
  # vault_secret_value_file = "${path.module}/charts/${var.name}/vault-token.yml.tftpl"
  # vault_secret_created    = fileexists(local.vault_secret_value_file) ? var.enabled : 0

  templates_path = "${path.module}/charts/${var.name}/templates"
  templates      = fileset(local.templates_path, "*.yml.tftpl")

  env_files = fileset("${local.templates_path}/envs/${var.environment}", "*.env")

  env_info = { for env in local.env_files : env => {
    name    = split(".", env)[0]
    content = filebase64("${local.templates_path}/envs/${var.environment}/${env}")
    }
  }
  # templates_enabled = length(local.templates) > 0 ? length(local.templates) : 0

  # serviceaccount_file = "${path.module}/charts/${var.name}/serviceaccount.json"
  # iam_role_created    = fileexists(local.serviceaccount_file) ? var.enabled : 0
}

# resource "kubernetes_namespace" "namespace" {
#   metadata {
#     annotations = {
#       name = var.namespace
#     }
#
#     labels = {
#       name = var.namespace
#     }
#
#     name = var.namespace
#   }
# }

resource "kubectl_manifest" "sc" {
  count = local.sc_created

  yaml_body = templatefile(local.sc_value_file, {
    parameters  = var.parameters
    namespace   = var.namespace
    environment = var.environment
  })
}

# Create the target namespace before the namespaced pre-helm manifests (tls) land.
resource "kubectl_manifest" "namespace" {
  count = local.ns_created

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata   = { name = var.namespace }
  })
}

# Pre-helm TLS manifests (cert-manager Issuer/Certificate chain). One resource per
# YAML doc. cert-manager reconciles these asynchronously; ordering between docs is
# not required (the CA Issuer/leaf become Ready once their backing Secret exists).
resource "kubectl_manifest" "tls" {
  count     = length(local.tls_docs)
  yaml_body = local.tls_docs[count.index]

  depends_on = [kubectl_manifest.namespace]
}

# resource "kubectl_manifest" "vault_token_secret" {
#   count = local.vault_secret_created
#
#   yaml_body = templatefile(local.vault_secret_value_file, {
#     parameters  = var.parameters
#     namespace   = var.namespace
#     environment = var.environment
#   })
# }
#
# resource "kubectl_manifest" "secret_store" {
#   count = local.secret_store_created
#
#   yaml_body = templatefile(local.secret_store_value_file, {
#     parameters  = var.parameters
#     namespace   = var.namespace
#     environment = var.environment
#   })
#
#   depends_on = [kubectl_manifest.vault_token_secret]
# }


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
          namespace   = var.namespace
          environment = var.environment
          parameters  = var.parameters
          env_info    = local.env_info
        },
      )
  ] : null)

  # Wait until all resources are ready
  wait          = true
  wait_for_jobs = true

  depends_on = [kubectl_manifest.namespace, kubectl_manifest.sc, kubectl_manifest.tls]
}

resource "kubectl_manifest" "templates" {
  for_each = var.enabled == 1 ? toset(local.templates) : toset([])
  # for_each = toset(local.templates)

  yaml_body = templatefile("${local.templates_path}/${each.value}", {
    parameters  = var.parameters
    namespace   = var.namespace
    environment = var.environment
  })

  depends_on = [
    helm_release.main,
    # kubectl_manifest.secret_store
  ]
}

# resource "kubectl_manifest" "envs_templates" {
#   for_each = var.enabled == 1 ? toset(local.env_files) : toset([])
#   # for_each = toset(local.templates)
#
#   yaml_body = templatefile("${local.templates_path}/envs/${var.environment}/${each.value}", {
#     parameters  = var.parameters
#     namespace   = var.namespace
#     environment = var.environment
#   })
#
#   depends_on = [
#     helm_release.main,
#     # kubectl_manifest.secret_store
#   ]
# }

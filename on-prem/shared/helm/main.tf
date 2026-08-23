locals {
  value_file = var.values_type == null ? "${path.module}/charts/${var.name}/values.yml.tftpl" : "${path.module}/charts/${var.name}/values.${var.values_type}.yml.tftpl"
  chart      = var.chart == null ? null : "${path.module}/charts/${var.name}"

  sc_value_file = "${path.module}/charts/${var.name}/sc.yml.tftpl"
  sc_created    = fileexists(local.sc_value_file) ? var.enabled : var.disabled

  # Pre-helm TLS material (e.g. cert-manager Issuer/Certificate chain for Vault).
  # Split the multi-doc template into individual manifests so kubectl_manifest (one
  # doc per resource) can apply each. fileexists-gated: no-op for charts without it.
  # Applied BEFORE helm_release so the referenced Secret exists at pod start.
  tls_value_file = "${path.module}/charts/${var.name}/tls.yml.tftpl"
  tls_docs = fileexists(local.tls_value_file) ? [
    for doc in split("\n---\n", templatefile(local.tls_value_file, {
      parameters  = var.parameters
      namespace   = var.namespace
      environment = var.environment
    })) : trimspace(doc) if trimspace(doc) != ""
  ] : []

  # ── Manifest (helm-less) mode ───────────────────────────────────────────────
  # When helm_release_enabled = false the chart installs NO Helm release; instead values.yml.tftpl
  # is treated as raw manifest(s) — the "main" resource, typically a CR (e.g. the Keycloak CR).
  # Multi-doc split so a bundle works too. The namespace is created here (helm's create_namespace
  # never runs). Used by operator-style charts that aren't Helm charts (keycloak-operator).
  manifest_mode = var.enabled == 1 && !var.helm_release_enabled
  main_manifest_docs = (local.manifest_mode && fileexists(local.value_file)) ? [
    for doc in split("\n---\n", templatefile(local.value_file, {
      namespace   = var.namespace
      environment = var.environment
      parameters  = var.parameters
      env_info    = local.env_info
    })) : trimspace(doc) if trimspace(doc) != ""
  ] : []

  # The target namespace must exist BEFORE the namespaced pre-helm manifests (tls) apply — OR before
  # any manifest-mode resource (helm's create_namespace never runs in manifest mode). Gate on tls
  # presence OR manifest mode so pure-Helm charts deploying into an existing ns are unaffected.
  # var.create_namespace is the explicit opt-out for pre-existing namespaces (see variables.tf) —
  # without it, manifest mode would adopt kube-system into state and a destroy would delete it.
  ns_created = (var.create_namespace && (fileexists(local.tls_value_file) || local.manifest_mode)) ? var.enabled : var.disabled

  templates_path = "${path.module}/charts/${var.name}/templates/exec"
  templates      = fileset(local.templates_path, "*.yml.tftpl")

  pre_templates_path = "${path.module}/charts/${var.name}/templates/pre-exec"
  pre_templates      = fileset(local.pre_templates_path, "*.yml.tftpl")

  post_templates_path = "${path.module}/charts/${var.name}/templates/post-exec"
  post_templates      = fileset(local.post_templates_path, "*.yml.tftpl")

  env_files = fileset("${local.templates_path}/envs/${var.environment}", "*.env")

  env_info = { for env in local.env_files : env => {
    name    = split(".", env)[0]
    content = filebase64("${local.templates_path}/envs/${var.environment}/${env}")
    }
  }

  # Render context shared by the exec-phase templates.
  tmpl_ctx = {
    parameters  = var.parameters
    namespace   = var.namespace
    environment = var.environment
  }

  # Split each exec-phase template FILE into individual YAML docs, so one file may hold multiple
  # resources (e.g. the keycloak operator bundle). Keyed by the filename for the FIRST doc — which
  # preserves the pre-existing single-doc resource ADDRESSES (no destroy/recreate) — and
  # "<file>#<n>" for any extra docs in the same file.
  pre_template_docs = (var.enabled == 1 && length(local.pre_templates) > 0) ? merge([
    for f in local.pre_templates : {
      for i, doc in [for d in split("\n---\n", templatefile("${local.pre_templates_path}/${f}", local.tmpl_ctx)) : trimspace(d) if trimspace(d) != ""] :
      (i == 0 ? f : "${f}#${i}") => doc
    }
  ]...) : {}

  exec_template_docs = (var.enabled == 1 && length(local.templates) > 0) ? merge([
    for f in local.templates : {
      for i, doc in [for d in split("\n---\n", templatefile("${local.templates_path}/${f}", local.tmpl_ctx)) : trimspace(d) if trimspace(d) != ""] :
      (i == 0 ? f : "${f}#${i}") => doc
    }
  ]...) : {}

  post_template_docs = (var.enabled == 1 && length(local.post_templates) > 0) ? merge([
    for f in local.post_templates : {
      for i, doc in [for d in split("\n---\n", templatefile("${local.post_templates_path}/${f}", local.tmpl_ctx)) : trimspace(d) if trimspace(d) != ""] :
      (i == 0 ? f : "${f}#${i}") => doc
    }
  ]...) : {}
}

resource "kubectl_manifest" "sc" {
  count = local.sc_created

  yaml_body = templatefile(local.sc_value_file, {
    parameters  = var.parameters
    namespace   = var.namespace
    environment = var.environment
  })
}

# Create the target namespace before the namespaced pre-helm manifests (tls) / manifest-mode docs.
resource "kubectl_manifest" "namespace" {
  count = local.ns_created

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata   = { name = var.namespace }
  })
}

# Pre-helm TLS manifests (cert-manager Issuer/Certificate chain). One resource per YAML doc.
resource "kubectl_manifest" "tls" {
  count     = length(local.tls_docs)
  yaml_body = local.tls_docs[count.index]

  depends_on = [kubectl_manifest.namespace]
}

resource "kubectl_manifest" "pre_templates" {
  for_each = local.pre_template_docs

  yaml_body          = each.value
  server_side_apply  = var.server_side_apply
  force_conflicts    = var.server_side_apply
  override_namespace = var.manifest_override_namespace

  depends_on = [
    helm_release.main,
    kubectl_manifest.namespace,
  ]
}

resource "helm_release" "main" {
  count            = var.enabled == 1 && var.helm_release_enabled ? 1 : 0
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

# Manifest-mode "main" (helm-less): values.yml.tftpl applied as raw manifest(s), e.g. a CR.
resource "kubectl_manifest" "main" {
  count = length(local.main_manifest_docs)

  yaml_body          = local.main_manifest_docs[count.index]
  server_side_apply  = var.server_side_apply
  force_conflicts    = var.server_side_apply
  override_namespace = var.manifest_override_namespace

  depends_on = [
    kubectl_manifest.namespace,
    kubectl_manifest.pre_templates,
  ]
}

resource "kubectl_manifest" "templates" {
  for_each = local.exec_template_docs

  yaml_body          = each.value
  server_side_apply  = var.server_side_apply
  force_conflicts    = var.server_side_apply
  override_namespace = var.manifest_override_namespace

  depends_on = [
    helm_release.main,
    kubectl_manifest.main,
  ]
}

resource "kubectl_manifest" "post_templates" {
  for_each = local.post_template_docs

  yaml_body          = each.value
  server_side_apply  = var.server_side_apply
  force_conflicts    = var.server_side_apply
  override_namespace = var.manifest_override_namespace

  depends_on = [
    helm_release.main,
    kubectl_manifest.main,
    kubectl_manifest.templates,
  ]
}

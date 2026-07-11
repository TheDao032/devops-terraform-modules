locals {
  # Only materialise the file list when enabled — keeps a disabled module a pure no-op.
  files = var.enabled == 1 ? var.crd_files : []

  # Split every bundle into individual YAML documents. Keep only real manifests: upstream
  # bundles carry a leading comment-only document (e.g. the Gateway API Apache license
  # header) and may have blank/`---` separators; those have no `kind:` and would fail
  # kubectl_manifest parsing.
  raw_docs = flatten([
    for f in local.files : [
      for d in split("\n---\n", file("${path.module}/files/${f}")) : trimspace(d)
      if trimspace(d) != "" && can(regex("(?m)^kind:", trimspace(d)))
    ]
  ])

  # Key each manifest by its CRD name (metadata.name) — stable, cluster-unique, and
  # human-readable in plan/apply/error output (e.g. "tlsroutes.gateway.networking.k8s.io"
  # instead of an opaque positional "<file>::7"). Then drop any excluded CRDs.
  all_docs = { for d in local.raw_docs : yamldecode(d).metadata.name => d }
  docs     = { for name, d in local.all_docs : name => d if !contains(var.exclude_crds, name) }
}

# CRDs applied with SERVER-SIDE apply on purpose. Client-side apply (the kubectl provider
# default) writes the full manifest into the kubectl.kubernetes.io/last-applied-configuration
# annotation, and the Gateway API CRD schemas blow past the 262 144-byte annotation cap
# ("metadata.annotations: Too long"). SSA stores no such annotation. force_conflicts lets
# us take ownership of fields a prior apply/controller may already manage.
resource "kubectl_manifest" "crd" {
  for_each = local.docs

  yaml_body         = each.value
  server_side_apply = true
  force_conflicts   = true

  # Block until the CRD's `Established` condition is true so dependents (Gateway,
  # HTTPRoute, IngressRoute, ServersTransport) can register against the new kinds.
  wait = true
}

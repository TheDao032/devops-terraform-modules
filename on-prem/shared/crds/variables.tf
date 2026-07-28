variable "enabled" {
  description = "1 to apply the CRDs, 0 to skip (mirrors the helm module's enable gate)."
  type        = number
  default     = 1

  validation {
    condition     = contains([0, 1], var.enabled)
    error_message = "enabled must be 0 (skip) or 1 (apply)."
  }
}

variable "exclude_crds" {
  description = <<-EOT
    CRD metadata.names to skip when applying the bundles.

    Empty by default. The cluster runs Kubernetes >= 1.31 (k3s 1.36 / k8s 1.36), so the
    apiserver's CEL library has isIP() and the TLSRoute CRD — whose hostname validation is
    "self.all(h, !isIP(h))" — applies cleanly. TLSRoute MUST be installed even though we route
    via HTTPRoute: Traefik v3's Gateway provider watches EVERY Gateway-API route kind, and a
    missing TLSRoute CRD stalls the whole provider's informer sync → GatewayClass stuck
    Accepted=Unknown, Gateway never programmed → every Gateway route 404s. (That was the argocd
    404 root cause on the old k8s-1.30 lab where this was excluded.) Only re-add
    "tlsroutes.gateway.networking.k8s.io" if you ever downgrade below k8s 1.31.
  EOT
  type        = list(string)
  default     = []

  validation {
    # Values are matched against yamldecode(...).metadata.name — CRD names are RFC1123 subdomains.
    condition = alltrue([
      for n in var.exclude_crds : can(regex("^[a-z0-9]([-a-z0-9.]*[a-z0-9])?$", n))
    ])
    error_message = "exclude_crds entries must be CRD metadata.name values (RFC1123 subdomain, e.g. \"tlsroutes.gateway.networking.k8s.io\")."
  }
}

variable "crd_files" {
  description = <<-EOT
    Filenames (relative to this module's files/ dir) of the pinned CRD bundles to apply.
    Each file may be a multi-document YAML; every document is applied as its own
    server-side-applied kubectl_manifest. Order matters only across modules (via
    depends_on), not within — CRDs have no inter-dependencies.

    Available bundles:
      - gateway-api-standard-v1.5.1.yaml   Gateway API standard channel (Gateway,
                                           GatewayClass, HTTPRoute, GRPCRoute,
                                           ReferenceGrant, BackendTLSPolicy)

    (Traefik's own traefik.io CRDs are NOT here — the Traefik Helm chart ships them in its
    crds/ dir and Helm auto-installs them, so no separate bundle is needed.)
  EOT
  type        = list(string)

  validation {
    condition     = length(var.crd_files) > 0
    error_message = "crd_files must list at least one bundle filename (relative to the module's files/ dir)."
  }

  validation {
    condition = alltrue([
      for f in var.crd_files : can(regex("\\.ya?ml$", f)) && !can(regex("/", f))
    ])
    error_message = "crd_files entries must be bare *.yaml/*.yml filenames (no path separators) resolved under files/."
  }
}

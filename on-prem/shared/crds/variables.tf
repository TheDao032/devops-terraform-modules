variable "enabled" {
  description = "1 to apply the CRDs, 0 to skip (mirrors the helm module's enable gate)."
  type        = number
  default     = 1
}

variable "exclude_crds" {
  description = <<-EOT
    CRD metadata.names to skip when applying the bundles.

    Default drops TLSRoute: its schema uses the CEL function isIP() in hostname
    validation ("self.all(h, !isIP(h))"), and isIP() only exists in the apiserver's CEL
    library on Kubernetes >= 1.31. This k3s lab runs 1.30, so applying it fails with
    "undeclared reference to 'isIP'". TLSRoute is experimental and unused here — routing
    goes through HTTPRoute + BackendTLSPolicy, not raw TLS/SNI passthrough. Clear this
    (set to []) once the cluster is on Kubernetes >= 1.31.
  EOT
  type        = list(string)
  default     = ["tlsroutes.gateway.networking.k8s.io"]
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
}

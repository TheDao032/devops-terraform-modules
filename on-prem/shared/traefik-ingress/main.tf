# ── Traefik Ingress for the *.fitmate.me platform hosts ────────────────────────────────────────
# cloudflared hands traffic to Traefik by Host header (Phase 2/3); these Ingresses tell Traefik which
# Service each *.fitmate.me host maps to. Created SEPARATELY from the Helm-managed *.k3s.* Ingresses
# (in the backend's own namespace) so Helm never reverts them. Providers (kubernetes, kubectl) come
# from the caller (root.hcl). See [[10-projects/production-cloudflare-tunnel]] Phase 3.

locals {
  labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = "cloudflare-tunnel"
  }
}

# One Ingress per host -> Service.
resource "kubernetes_ingress_v1" "route" {
  for_each = var.routes

  metadata {
    name      = replace(each.key, ".", "-")
    namespace = each.value.namespace
    labels    = local.labels
    annotations = merge(
      { "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure" },
      each.value.https ? { "traefik.ingress.kubernetes.io/service.serversscheme" = "https" } : {},
      each.value.servers_transport != "" ? { "traefik.ingress.kubernetes.io/service.serverstransport" = each.value.servers_transport } : {},
    )
  }

  spec {
    ingress_class_name = var.ingress_class

    rule {
      host = each.key
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = each.value.service
              port {
                number = each.value.port
              }
            }
          }
        }
      }
    }
  }
}

# Traefik dashboard = the internal `api@internal` service (not a k8s Service), so it MUST be a Traefik
# IngressRoute CRD rather than a standard Ingress. Applied via kubectl_manifest (alekc/kubectl).
resource "kubectl_manifest" "traefik_dashboard" {
  count = var.traefik_dashboard == null ? 0 : 1

  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "traefik-dashboard-fitmate"
      namespace = var.traefik_dashboard.namespace
      labels    = local.labels
    }
    spec = {
      entryPoints = ["web", "websecure"]
      routes = [{
        kind  = "Rule"
        match = "Host(`${var.traefik_dashboard.host}`)"
        services = [{
          kind = "TraefikService"
          name = "api@internal"
        }]
      }]
    }
  })
}

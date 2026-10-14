# IN-40 / ADR-109 layer 1 — the per-namespace ingress default-deny baseline.
#
# Dao chose the two-layer design over my gitops-only recommendation, for a reason
# that decided it: "the deny default cannot be forgotten when a new service is
# onboarded". App-specific allows alone leave a namespace created tomorrow fully
# open, with nothing in the process forcing anyone to notice. This module makes
# CLOSED the default and an allow rule the deliberate act.
#
# 🔴 INGRESS ONLY. An egress default-deny would break Postgres (192.168.105.10),
# Kafka, Vault, CoreDNS and the PVC in one apply. Egress restriction is its own
# ticket with its own measurement — NOT smuggled in here.
#
# 🔴 THE TWO ALLOWS ARE NOT OPTIONAL. A bare default-deny is "secure" and also:
#   - 504s every public route (traefik can no longer reach the pod), and
#   - blinds prometheus, which looks like a healthy quiet service.
# Both are included so this baseline is safe to apply to EVERY fitmate namespace.
# Measured 2026-10-14: media-service has no ServiceMonitor and no HTTPRoute today,
# so for THAT namespace both rules are defensive rather than load-bearing — but six
# other namespaces do have a public route and would break without the traefik rule.
#
# 🔴 ENFORCEMENT PROVEN BEFORE THIS MODULE WAS WRITTEN. k3s runs flannel and the
# netpol controller inside the agent process, so there is no CNI pod to inspect.
# Applied a deny-all to fitmate-media-dev and probed, twice, then removed it:
#   round 1: before rc=0 -> deny-all rc=4 BLOCKED -> removed rc=0
#   round 2: before rc=0 -> deny-all rc=4 BLOCKED -> removed rc=0
# An unenforced policy is a green status attesting to the wrong proposition.

locals {
  # One policy per namespace. Allows union across every policy selecting a pod, so
  # the gitops layer-2 rules can only WIDEN this, never narrow it.
  baseline = {
    for ns in var.namespaces : ns => yamlencode({
      apiVersion = "networking.k8s.io/v1"
      kind       = "NetworkPolicy"
      metadata = {
        name      = "zz-baseline-default-deny-ingress"
        namespace = ns
        labels = {
          "app.kubernetes.io/managed-by" = "terraform"
          "fitmate.me/adr"               = "adr-109"
        }
        annotations = {
          # Names the OTHER layer, so whoever finds this policy while debugging a
          # blocked connection knows where the matching allow lives.
          "fitmate.me/app-allows" = "fitmate-gitops: platform/netpol/<env>/<service>.yaml"
        }
      }
      spec = {
        podSelector = {}
        policyTypes = ["Ingress"]
        ingress = [
          {
            from = [{
              namespaceSelector = {
                matchLabels = { "kubernetes.io/metadata.name" = var.ingress_namespace }
              }
            }]
          },
          {
            from = [{
              namespaceSelector = {
                matchLabels = { "kubernetes.io/metadata.name" = var.monitoring_namespace }
              }
            }]
          },
        ]
      }
    })
  }
}

resource "kubectl_manifest" "baseline" {
  for_each = local.baseline

  yaml_body = each.value

  # The namespace is created by ArgoCD (CreateNamespace=true), not here. Verified:
  # fitmate-media-dev carries only kubernetes.io/metadata.name and no ownership
  # labels. So this module must NOT try to manage the namespace itself.
  wait_for_rollout = false
}

output "policy_names" {
  description = "Namespace -> baseline policy name, for the verification probe."
  value       = { for ns in var.namespaces : ns => "zz-baseline-default-deny-ingress" }
}

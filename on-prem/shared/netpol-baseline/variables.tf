variable "namespaces" {
  description = <<-EOT
    Namespaces that receive the ingress default-deny baseline.

    Each listed namespace gets ONE policy: deny all ingress, then allow the two
    sources every FITMate namespace needs (traefik, prometheus). App-specific
    allows live in gitops next to the workload — see ADR-109.
  EOT
  type        = list(string)

  # 🔴 AN EMPTY LIST IS ALLOWED, DELIBERATELY.
  #
  # The original rule here rejected it, reasoning that "an empty baseline silently
  # protects nothing". That is true as a steady state and wrong as a transition:
  # when this baseline had to be ROLLED BACK after two production failures
  # (2026-10-14), the only safe way to reconcile terraform state with the cluster
  # was to apply an empty list so the tracked policies are DESTROYED.
  #
  # Rejecting empty forced the alternative — leaving the old namespace list in the
  # unit — which means the next apply by anyone SILENTLY RECREATES THE OUTAGE while
  # the repo still claims the baseline is enabled. A validation rule that makes
  # rollback impossible is worse than no rule.
  #
  # The protection against a silently-empty baseline belongs in review, not here:
  # the unit must carry a comment saying WHY it is parked. See
  # on-prem/fitmate/{dev,stg}/netpol-baseline/terragrunt.hcl.

  validation {
    condition     = alltrue([for n in var.namespaces : can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", n))])
    error_message = "every namespace must be a valid RFC1123 label."
  }
}

variable "ingress_namespaces" {
  description = <<-EOT
    Namespaces that must be allowed to reach every workload, because the ingress
    path runs across BOTH of them.

    🔴 THIS DEFAULT WAS WRONG AND TOOK DEV AND STG DOWN (2026-10-14).

    I set it to a single "kube-system" on the belief that k3s bundles traefik
    there. It does not. Measured after the outage:

      kube-system   svclb-traefik-099b4618-{2mgbj,l864g,mvrjg,v58dd}
      traefik       traefik-65dcbbf4b8-7wbwv      <-- the actual proxy

    kube-system holds only the svclb (ServiceLB) helper pods that forward the
    node port. The Traefik deployment that terminates TLS and proxies every
    public request lives in a namespace called "traefik". Allowing only
    kube-system blocked the proxy, and web-dev, admin-dev and web-stg all
    returned 502 while every pod stayed 1/1 Running.

    Both are listed because the hop genuinely traverses both: svclb forwards
    from the node, traefik originates the proxied connection to the pod.
  EOT
  type        = list(string)
  default     = ["traefik", "kube-system"]

  validation {
    condition     = length(var.ingress_namespaces) > 0
    error_message = "ingress_namespaces must not be empty — an empty list blocks all public traffic."
  }
}

variable "monitoring_namespace" {
  description = "Namespace running prometheus. Allowed so a future ServiceMonitor is not silently blocked (IN-26)."
  type        = string
  default     = "monitoring"
}

variable "namespaces" {
  description = <<-EOT
    Namespaces that receive the ingress default-deny baseline.

    Each listed namespace gets ONE policy: deny all ingress, then allow the two
    sources every FITMate namespace needs (traefik, prometheus). App-specific
    allows live in gitops next to the workload — see ADR-109.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.namespaces) > 0
    error_message = "namespaces must not be empty — an empty baseline silently protects nothing."
  }

  validation {
    condition     = alltrue([for n in var.namespaces : can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", n))])
    error_message = "every namespace must be a valid RFC1123 label."
  }
}

variable "ingress_namespace" {
  description = "Namespace running the ingress controller. k3s bundles traefik in kube-system."
  type        = string
  default     = "kube-system"
}

variable "monitoring_namespace" {
  description = "Namespace running prometheus. Allowed so a future ServiceMonitor is not silently blocked (IN-26)."
  type        = string
  default     = "monitoring"
}

variable "rbacs" {
  description = <<-EOT
    Service-account RBAC bundles, keyed by name (e.g. "traefik"). main.tf does `for_each`
    over this map; each entry creates a ServiceAccount + ClusterRole + ClusterRoleBinding +
    SA-token Secret. Shape per entry:
      {
        sa                   = { metadata = { name, namespace } }
        cluster_role         = { metadata = { name }, rule = { api_groups, resources, verbs } }
        cluster_role_binding = { metadata = { name } }
      }
  EOT
  type = map(object({
    sa = object({
      metadata = object({
        name      = string
        namespace = string
      })
    })
    cluster_role = object({
      metadata = object({
        name = string
      })
      rule = object({
        api_groups = list(string)
        resources  = list(string)
        verbs      = list(string)
      })
    })
    cluster_role_binding = object({
      metadata = object({
        name = string
      })
    })
  }))
  default = {}

  validation {
    # SA name + namespace and both role names are RFC1123 k8s object names (metadata.name).
    condition = alltrue([
      for k, v in var.rbacs : alltrue([
        for n in [
          v.sa.metadata.name,
          v.sa.metadata.namespace,
          v.cluster_role.metadata.name,
          v.cluster_role_binding.metadata.name,
        ] : can(regex("^[a-z0-9]([-a-z0-9.]*[a-z0-9])?$", n))
      ])
    ])
    error_message = "rbacs.<name>.{sa,cluster_role,cluster_role_binding}.metadata names/namespace must be RFC1123 (lowercase alphanumeric, '-' or '.', start/end alphanumeric)."
  }

  validation {
    condition = alltrue([
      for k, v in var.rbacs : length(v.cluster_role.rule.verbs) > 0
    ])
    error_message = "rbacs.<name>.cluster_role.rule.verbs must list at least one verb."
  }
}

variable "tags" {
  description = "Resource tags applied where the provider supports them."
  type        = map(string)
  default     = {}
}

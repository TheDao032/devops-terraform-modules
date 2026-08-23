# Generic helm wrapper module. `parameters`/`tags` are freeform maps piped straight into
# templatefile()/helm_release.values — they MUST stay `any`. `enabled`/`disabled` are
# count-style ints (0/1) driving resource count. `chart`/`values_type` are nullable by contract.

variable "environment" {
  description = "Environment name — passed into every templatefile() render as `environment`."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "namespace" {
  description = "Kubernetes namespace the helm release and pre-helm manifests deploy into."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid RFC 1123 DNS label (lowercase alphanumeric and '-')."
  }
}

variable "enabled" {
  description = "Count-style toggle: 1 creates the helm_release (and gated manifests), 0 disables it."
  type        = number
  default     = 1

  validation {
    condition     = contains([0, 1], var.enabled)
    error_message = "enabled must be 0 or 1 (used as a resource count)."
  }
}

variable "disabled" {
  description = "Count-style off value used when a fileexists()-gated manifest should not be created."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1], var.disabled)
    error_message = "disabled must be 0 or 1 (used as a resource count)."
  }
}

variable "chart" {
  description = "Local chart path selector. When null the release uses a local ./charts/<name> dir; otherwise the remote repository chart."
  type        = string
  default     = null
}

variable "name" {
  description = "Helm release name and the ./charts/<name> subdirectory selector."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must be a non-empty string (it selects the chart dir and names the release)."
  }
}

variable "repository" {
  description = "Helm chart repository URL. Empty in manifest mode (helm_release_enabled = false)."
  type        = string
  default     = ""
}

variable "chart_version" {
  description = "Helm chart version to install. Empty in manifest mode (helm_release_enabled = false)."
  type        = string
  default     = ""
}

variable "values_type" {
  description = "Selects the values template variant: values.<values_type>.yml.tftpl. Null uses the default values.yml.tftpl."
  type        = string
  default     = null
}

# ── Manifest (helm-less) mode ─────────────────────────────────────────────────
# These three are opt-in; their defaults reproduce the classic Helm-chart behaviour exactly, so
# existing charts are unaffected. Set them for operator/CR charts that aren't Helm charts (the
# chart dir is still just values.yml.tftpl + templates/, e.g. keycloak-operator).

variable "create_namespace" {
  # ⚠️ Set FALSE when deploying into a namespace this module does not own — above all kube-system.
  #
  # The namespace resource is a plain kubectl_manifest with no adoption guard, so applying it for an
  # EXISTING namespace silently puts that namespace under Terraform's ownership in state. A later
  # `destroy` of this module would then try to DELETE it. For an app namespace that is merely
  # untidy; for kube-system it would take the cluster down.
  #
  # Caught while adding the coredns-custom manifest (IN-16 stage 2), whose plan read
  # "module.coredns-custom.kubectl_manifest.namespace[0] will be created" against a kube-system
  # that has existed since the cluster was built.
  description = "Whether this module should create its namespace. False when deploying into a pre-existing one."
  type        = bool
  default     = true
}

variable "helm_release_enabled" {
  description = "true = install a Helm chart (values.yml.tftpl = helm values). false = MANIFEST mode: NO helm_release; values.yml.tftpl is applied as raw kubectl manifest(s) — the 'main' resource (multi-doc split)."
  type        = bool
  default     = true
}

variable "server_side_apply" {
  description = "Apply the chart's kubectl manifests (main + pre/exec/post) with server-side apply + force_conflicts. Needed for large manifests (operator ClusterRoles exceed the client-side last-applied annotation limit). Default false = client-side (unchanged for existing charts)."
  type        = bool
  default     = false
}

variable "manifest_override_namespace" {
  description = "When set, forces this namespace onto the chart's kubectl manifests (main + pre/exec/post) via override_namespace — for upstream bundles shipped namespace-less (e.g. the keycloak operator). Null (default) = no override; cluster-scoped docs ignore it server-side."
  type        = string
  default     = null
}

variable "parameters" {
  # ⚠️ `any`, NOT `map(any)`. The comment here has always said "freeform", but map(any) is not
  # freeform: Terraform unifies every element to a single type, so the moment one caller mixes a
  # string with a list or object it fails with
  #     "all map elements must have the same type"
  # pointing at the CALLER's block rather than at this declaration — which reads like the caller
  # wrote something invalid. It did not; the type was lying about its own contract.
  #
  # Hit while adding traefik's public_host_certs (a list of objects) alongside dashboard_host (a
  # string). Charts that pass a single nested key never triggered it, which is why it survived.
  description = "Chart's parameters — freeform values rendered into the chart's values/manifest templates."
  type        = any
  default     = {}
}

variable "tags" {
  # intentionally any: freeform metadata map
  description = "Tags"
  type        = map(any)
  default     = {}
}

variable "host" {
  description = "Kubernetes API server host (inherited provider context)."
  type        = string

  validation {
    condition     = length(trimspace(var.host)) > 0
    error_message = "host must be a non-empty string."
  }
}

variable "client_key" {
  description = "PEM-encoded client private key for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

variable "client_certificate" {
  description = "PEM-encoded client certificate for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "PEM-encoded cluster CA certificate used to verify the Kubernetes API server."
  type        = string
  sensitive   = true
}

variable "token" {
  description = "Bearer token for Kubernetes API authentication."
  type        = string
  sensitive   = true
}

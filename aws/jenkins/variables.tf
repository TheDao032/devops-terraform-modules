variable "chart_version" {
  description = "Version of the jenkins/jenkins Helm chart to deploy."
  type        = string
  default     = "5.7.3"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "chart_version must be a semantic version (e.g. \"5.7.3\")."
  }
}

variable "jenkins_version" {
  description = "Jenkins controller image tag rendered into the Helm values."
  type        = string
  default     = "2.479-jdk17"

  validation {
    condition     = length(trimspace(var.jenkins_version)) > 0
    error_message = "jenkins_version must be a non-empty image tag."
  }
}

variable "parameters" {
  description = "Freeform Helm values merged into the rendered values.yaml template. Shape is chart-specific."
  # intentionally any: merged straight into the Jenkins Helm values via templatefile(); the value set
  # is defined by the chart and by the caller's values template, so it is genuinely heterogeneous.
  type    = any
  default = {}

  validation {
    condition     = can(keys(var.parameters))
    error_message = "parameters must be a map of Helm values (map(any))."
  }
}

variable "jenkins_plugins" {
  description = "Plugin set injected into the Helm values template. Shape is chart/template specific."
  # intentionally any: passed through to the values template as-is; callers may supply a map keyed by
  # plugin name with heterogeneous config, so a tighter type would reject valid inputs.
  type    = any
  default = {}

  validation {
    condition     = can(keys(var.jenkins_plugins))
    error_message = "jenkins_plugins must be a map (map(any))."
  }
}

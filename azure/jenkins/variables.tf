variable "chart_version" {
  description = "Version of the jenkins/jenkins Helm chart to deploy (helm_release.version)."
  type        = string
  default     = "5.7.3"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "chart_version must be a semantic version (e.g. \"5.7.3\")."
  }
}

variable "jenkins_version" {
  description = "Jenkins controller image tag (rendered into controller.image.tag)."
  type        = string
  default     = "2.479-jdk17"

  validation {
    condition     = length(trimspace(var.jenkins_version)) > 0
    error_message = "jenkins_version must be a non-empty image tag."
  }
}

variable "parameters" {
  # intentionally any: freeform key/value map merged into the values.yml.tftpl templatefile
  # context (e.g. jenkins_url, jenkins_username, jenkins_password) — values are heterogeneous
  # template inputs, not a fixed schema. Marked sensitive because it may carry jenkins_password.
  description = "Freeform template variables merged into the Helm values templatefile (may include secrets such as jenkins_password)."
  type        = map(any)
  default     = {}
  sensitive   = true

  validation {
    condition     = can(keys(var.parameters))
    error_message = "parameters must be a map of template variables."
  }
}

variable "jenkins_plugins" {
  description = "Plugins to install, keyed by plugin id with the version as value (rendered as \"<id>:<version>\")."
  type        = map(string)
  default     = {}
}

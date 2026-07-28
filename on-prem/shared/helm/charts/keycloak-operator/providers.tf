# No module-local `provider "kubectl"` block on purpose — declaring one makes this a "legacy
# module" and forbids depends_on on the module call (we need it: the Keycloak CR must apply
# AFTER the operator + DB Secret). The root (terragrunt root.hcl generate) injects a configured
# kubectl provider which this module inherits — same as shared/crds, shared/routing, shared/helm.
terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
}

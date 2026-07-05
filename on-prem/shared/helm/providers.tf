# NOTE: no `provider "kubectl"` config block here on purpose. Declaring a provider
# config inside a module makes it a "legacy module" that can't use count/for_each/
# depends_on. The root (terragrunt `generate "provider"` in root.hcl) already provides
# a fully-configured kubectl/kubernetes/helm provider, which this module inherits.
# Keep only required_providers so the alekc/kubectl source stays pinned.
terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
}

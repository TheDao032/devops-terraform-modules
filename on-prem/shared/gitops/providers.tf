# Source pins only — NO `provider` config blocks. The root (terragrunt's kube.hcl partial) generates
# the configured kubectl/kubernetes/helm providers into the stack, and this module INHERITS them
# automatically as a child module. Declaring a `provider "..." {}` here would (a) duplicate/override
# that inherited config and (b) make this a "legacy module" that can't use count/for_each/depends_on.
# Only alekc/kubectl strictly needs the source pin (community provider, not source-inferable).
terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.4.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2.1"
    }
  }
}

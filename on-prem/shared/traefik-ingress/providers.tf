# alekc/kubectl is a COMMUNITY provider — Terraform can't source-infer it (it assumes the
# nonexistent hashicorp/kubectl), so every module using kubectl_manifest must declare its source.
# No `provider "kubectl"` config block here on purpose: that would make this a "legacy module"
# (no count/for_each/depends_on). The root (terragrunt provider partial) injects the configured
# kubectl/kubernetes/helm providers, which this module inherits. required_providers only.
# terraform {
#   required_providers {
#     kubectl = {
#       source  = "alekc/kubectl"
#       version = "~> 2.4.1"
#     }
#   }
# }

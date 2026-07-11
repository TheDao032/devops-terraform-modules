# CRDs are cluster-scoped, install-once resources. We apply them OUTSIDE Helm on
# purpose: the traefik-crds Helm chart embeds ~3.1 MB of CRD source (crds-files/),
# and Helm stores the WHOLE chart in its release Secret — which exceeds etcd's 1 MiB
# object cap ("Secret ... data: Too long: must have at most 1048576 bytes"). No value
# toggle avoids this because the toggles only gate RENDERING, not what the chart ships.
#
# No `provider "kubectl"` config block here — declaring one would forbid the caller
# from passing depends_on to this module. The root module injects a fully-configured
# kubectl provider (server URL, token, CA) which this module inherits. Keep only
# required_providers so the alekc/kubectl source stays pinned.
terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
}

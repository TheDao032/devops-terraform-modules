locals {
  gateway_api_manifests = toset([
    "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml",
  ])

  # Convert the list of YAML documents into a map for proper iteration
  crds_map = { for k, docs in data.kubectl_file_documents.crds : k => docs.documents }
}

data "http" "crds" {
  for_each = local.gateway_api_manifests
  url      = each.key
}

# Split multi-document YAML into individual manifests for each URL
data "kubectl_file_documents" "crds" {
  for_each = data.http.crds
  content  = each.value.response_body
}


# Apply each CRD document
resource "kubectl_manifest" "gateway_api_crds" {
  for_each  = { for idx, doc in flatten(values(local.crds_map)) : idx => doc }
  yaml_body = each.value
}

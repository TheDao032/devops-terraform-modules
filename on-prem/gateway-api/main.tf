locals {
  gateway_api_manifests = toset([
    "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml",
  ])

  # flattened_gateway_api_crds_raw = flatten([
  #   for path, creds in local.secrets_parameters : [
  #     for key, value in creds : {
  #       path  = path
  #       key   = key
  #       value = value
  #     }
  #   ]
  # ])
}

data "http" "gateway_api_crds_raw" {
  for_each = local.gateway_api_manifests
  url      = each.key
}

# resource "kubectl_manifest" "storage_class" {
#   yaml_body = templatefile(local.traefik_gateway_class_file, {
#     gateway_class_name = local.traefik_gateway_class_name
#   })
# }

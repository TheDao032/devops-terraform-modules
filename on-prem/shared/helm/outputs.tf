# output "filtered_secret_store_name" {
#   value = var.name == "external-secrets" ? var.parameters.common.secret_store_name : null
# }

output "argocd_server_url" {
  value = var.name == "argo-cd" ? var.parameters.ingress.domain : null
}

output "argocd_namespace" {
  value = var.name == "argo-cd" ? var.namespace : null
}

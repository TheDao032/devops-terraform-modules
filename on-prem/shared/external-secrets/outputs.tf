# output "filtered_secret_store_name" {
#   value = module.external-secrets.filtered_secret_store_name
# }

output "local_backend_name" {
  value = "${local.local_common.namespace}-backend"
}

output "gitops_backend_name" {
  value = "${local.gitops_common.namespace}-backend"
}

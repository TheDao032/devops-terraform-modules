# locals {
#   value_file         = "${path.module}/argocd/templates/values/values.yml.tftpl"
# }
#
# resource "helm_release" "argocd" {
#   name             = var.argocd_conf.chart_info.helm_release_name
#   namespace        = var.argocd_conf.chart_info.namespace
#   repository       = var.argocd_conf.chart_info.helm_repository
#   version          = var.argocd_conf.chart_info.chart_version
#   chart            = var.argocd_conf.chart_info.helm_release_chart
#   create_namespace = true
#   upgrade_install  = true
#   values = (fileexists(local.value_file) ?
#     [
#       templatefile(
#         local.value_file,
#         merge(
#           var.parameters, {},
#         )
#       )
#   ] : null)
# }

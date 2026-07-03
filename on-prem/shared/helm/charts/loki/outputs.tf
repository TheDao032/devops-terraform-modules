output "internal_loki_server" {
  value = "${var.loki_helm_release_name}-query-frontend.${var.namespace}.svc.cluster.local"
}

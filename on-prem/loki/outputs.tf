output "internal_loki_server" {
  value = "${var.loki_helm_release_name}.${var.namespace}.svc.cluster.local"
}

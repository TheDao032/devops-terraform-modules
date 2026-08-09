output "namespace" {
  description = "Namespace the cloudflared connector runs in."
  value       = kubernetes_namespace_v1.main.metadata[0].name
}

output "deployment" {
  description = "cloudflared Deployment name."
  value       = kubernetes_deployment_v1.main.metadata[0].name
}

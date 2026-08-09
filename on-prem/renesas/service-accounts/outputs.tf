output "traefik_sa_token" {
  value     = kubernetes_secret_v1.traefik_sa_token.data["token"]
  sensitive = true
}

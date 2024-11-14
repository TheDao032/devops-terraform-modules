output "traefik_sa_token" {
  value     = kubernetes_secret.traefik_sa_token.data["token"]
  sensitive = true
}

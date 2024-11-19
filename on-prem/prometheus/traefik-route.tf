resource "kubernetes_manifest" "prometheus_prefix" {
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "Middleware"
    "metadata" = {
      "name"      = "prometheus-prefix"
      "namespace" = "kube-system"
    }
    "spec" = {
      "stripPrefix" = {
        "prefixes" = ["/prometheus"]
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_manifest" "grafana_prefix" {
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "Middleware"
    "metadata" = {
      "name"      = "grafana-prefix"
      "namespace" = "kube-system"
    }
    "spec" = {
      "stripPrefix" = {
        "prefixes" = ["/grafana"]
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_manifest" "alertmanager_prefix" {
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "Middleware"
    "metadata" = {
      "name"      = "alertmanager-prefix"
      "namespace" = "kube-system"
    }
    "spec" = {
      "stripPrefix" = {
        "prefixes" = ["/alertmanager"]
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca_cert" {
  # key_algorithm   = tls_private_key.ca_key.algorithm
  private_key_pem = tls_private_key.ca_key.private_key_pem

  # Certificate expires after 10 years.
  validity_period_hours = 87600

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 168

  # Reasonable set of uses for a server SSL certificate.
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "server_auth",
    "client_auth",
  ]

  dns_names = ["renesas.plm.com"]

  subject {
    common_name  = "renesas.plm.com"
    organization = "Renesas, Inc"
    country      = "VN"
  }

  is_ca_certificate = true
  depends_on = [ tls_private_key.ca_key ]
}

# 3. Generate a private key for Vault
resource "tls_private_key" "vault_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 4. Create a certificate request for Vault
resource "tls_cert_request" "vault_cert_request" {
  # key_algorithm   = "RSA"
  private_key_pem = tls_private_key.vault_key.private_key_pem

  dns_names = ["renesas.plm.com"]

  subject {
    common_name  = "renesas.plm.com"
    organization = "Renesas, Inc"
    country      = "VN"
  }

  depends_on = [ tls_private_key.vault_key ]
}

# 5. Sign the Vault certificate request with the CA
resource "tls_locally_signed_cert" "vault_cert" {
  cert_request_pem = tls_cert_request.vault_cert_request.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "server_auth",
    "client_auth",
  ]

  # Certificate expires after 1 years.
  validity_period_hours = 8760

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 21

  depends_on = [ tls_private_key.ca_key, tls_self_signed_cert.ca_cert, tls_cert_request.vault_cert_request ]
}

resource "kubernetes_secret" "ca_secret" {
  metadata {
    name = "vault-tls-ca"
    namespace = "vault"
  }

  data = {
    "tls.crt" = tls_self_signed_cert.ca_cert.cert_pem
    "tls.key" = tls_private_key.ca_key.private_key_pem
  }

  type = "kubernetes.io/tls"

  depends_on = [ tls_self_signed_cert.ca_cert, tls_private_key.ca_key ]
}

resource "kubernetes_secret" "vault_secret" {
  metadata {
    name = "vault-tls-server"
    namespace = "vault"
  }

  data = {
    "tls.crt" = tls_locally_signed_cert.vault_cert.cert_pem
    "tls.key" = tls_private_key.vault_key.private_key_pem
  }

  type = "kubernetes.io/tls"

  depends_on = [ tls_locally_signed_cert.vault_cert, tls_private_key.vault_key ]
}


locals {
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = var.github_oidc_url

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = var.thumbprint

  tags = merge(var.tags, {
    Name = "github-oidc-provider"
  })
}


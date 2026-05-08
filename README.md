# Terraform modules

Reusable, **tenant-agnostic** Terraform modules for on-prem and public-cloud
platform components. Consumed by sibling repo
[`devops-terragrunt-environments`](../devops-terragrunt-environments/).

## Repository layout

```
on-prem/                     ← generic modules; ONE module per concern
├── helm/                    ← generic helm-release meta-module
│   ├── main.tf
│   ├── variables.tf         ← name, repository, chart_version, parameters (free-form map), …
│   └── charts/<chart>/      ← per-chart values templates / self-contained submodules
├── apps/                    ← gitops wrapper for individual apps
├── external-secrets/        ← namespaced ESO + Vault token wiring
├── gitops/                  ← ArgoCD Application factory + per-app submodules
├── k3s/                     ← cluster-bootstrap addons (calls helm meta-module 6×+)
├── router/                  ← generic Traefik / Nginx middleware + ingress
├── secrets-stored/          ← per-namespace ESO SecretStore (+ vault token)
├── service-accounts/        ← k8s SAs + RBAC
├── vault-roles/             ← Vault AppRole + policies
└── vault-secrets/           ← Vault KV-v2 mount + random-password expansion

aws/   azure/   gcp/         ← per-resource discrete cloud modules (most are stubs)
```

## Tenancy model

**Tenants live only in the consumer repo (`devops-terragrunt-environments`),
not here.** Each tenant calls the same generic module with different
`inputs = { ... }`.

| Concern | Where it lives |
|---|---|
| Module logic (HCL) | this repo, `on-prem/<module>/main.tf` |
| Per-chart values templates / supplementary manifests | this repo, `on-prem/helm/charts/<chart>/` |
| Per-tenant variance (chart version, namespace, ingress hosts, secrets) | sibling repo, `on-prem/<tenant>/<env>/<resource>/terragrunt.hcl` `inputs` |
| Per-tenant runtime credentials (KUBE_*, VAULT_TOKEN) | sibling repo, `deployments/on-prem/<tenant>/envs/<env>/*.bash` |

Adding a tenant means adding env-tree + deploy-env files in the consumer
repo. **It does not mean copying any module here.**

## The two flavours of helm chart in `on-prem/helm/charts/`

### Flavour A — values-template only

Consumed by the `on-prem/helm` meta-module's `templatefile()` + `helm_release`
pathway. Caller passes `name = "<chart>"`; meta-module reads
`charts/<name>/values.yml.tmpl` (+ optional `sc.yml.tmpl` and
`templates/*.yml.tmpl`).

Charts: `argo-cd`, `argocd-image-updater`, `consul`, `core-dns`,
`external-secrets`, `jenkins`, `kafka`, `kong`, `nginx-gateway-fabric`,
`reloader`, `vault`.

### Flavour B — self-contained submodules

Have their own `main.tf` + `variables.tf` + `outputs.tf`. NOT consumed via
the meta-module — caller invokes them directly:

```hcl
module "cert_manager" {
  source = "../helm/charts/cert-manager"
  helm_release_name = "cert-manager"
  …
}
```

Charts: `cert-manager`, `kafka-ui`, `keycloak`, `loki`, `prometheus`.

These have richer typed inputs (e.g. `helm_release_name`, ingress configs,
external-loki URLs) and create supplementary k8s manifests beyond the helm
release (Traefik Middlewares, IngressRoutes, ClusterIssuers, etc.).

## Consumer call patterns

### Per-chart leaf using the meta-module (Flavour A)

```hcl
# devops-terragrunt-environments/on-prem/<tenant>/<env>/<some-leaf>/terragrunt.hcl
terraform {
  source = "../../../../../devops-terraform-modules//on-prem/helm"
}

inputs = {
  name          = "jenkins"           # → reads charts/jenkins/values.yml.tmpl
  repository    = "https://charts.jenkins.io/"
  chart_version = "5.7.3"
  namespace     = "jenkins"
  environment   = local.environment
  parameters    = { common = {…}, ingress = {…}, secret = {…} }
  # plus the K8s creds passthrough: host, client_key, client_certificate, …
}
```

### Per-chart leaf using a self-contained submodule (Flavour B)

```hcl
terraform {
  source = "../../../../../devops-terraform-modules//on-prem/helm/charts/cert-manager"
}

inputs = {
  helm_release_name      = "cert-manager"
  namespace              = "default"
  chart_version          = "1.16.1"
  cloudflare_secret_name = "..."
  cloudflare_api_token   = "..."
  email                  = "..."
}
```

### Bootstrap-cluster leaf using `on-prem/k3s` (recommended)

```hcl
terraform {
  source = "../../../../../devops-terraform-modules//on-prem/k3s"
}

inputs = {
  external_secrets_conf = { helm = {…}, secret = {…}, common = {} }
  argocd_conf           = { helm = {…}, ingress = {…}, github = {…}, common = {…} }
  reloader_conf         = { helm = {…}, common = {…} }
  jenkins_conf          = { helm = {…}, secrets = {…}, common = {…}, plugins = {…} }
  coredns_conf          = { helm = {…}, common = {} }
  kafka_conf            = { helm = {…}, controller = {…}, broker = {…}, sasl = {…} }
  consul_conf           = { helm = {…}, server = {…}, common = {} }
  vault_conf            = { helm = {…}, server = {…}, ui = {…}, injector = {…}, common = {…} }
}
```

The `on-prem/k3s` module calls the helm meta-module 6× internally with
each `*_conf` block, plus passes outputs (e.g. `argocd_server_url`) to
downstream modules like `argocd-image-updater`.

### Non-helm modules

```hcl
# vault-secrets, vault-roles, external-secrets, service-accounts, apps
terraform { source = "../../../../../devops-terraform-modules//on-prem/<module>" }
```

## Conventions

- **3 files per module minimum:** `main.tf`, `variables.tf`, `outputs.tf`.
- **Helm values & k8s manifests** live as `*.yml.tmpl` (Flavour A) or
  `*.yml.tftpl` (Flavour B) and are read via `templatefile()`.
- **No shared `terraform { backend ... }` block** — backends are configured
  by the consumer (terragrunt) per (tenant, env).
- **No hard-coded secrets.** Pull from Vault via the consumer's
  `vault-secrets` chain.
- **`parameters` map shape is convention, not contract.** Each chart's
  values template is the source of truth for what keys it expects.
- **K8s creds are inputs, not provider config.** Modules take `host`,
  `client_key`, `client_certificate`, `cluster_ca_certificate`, `token` as
  variables; the consumer's root terragrunt template generates the actual
  `helm` / `kubernetes` providers.

## Cloud subtrees (aws/, azure/, gcp/)

Per-resource discrete modules, NOT a parametrized factory.

| Module | State |
|---|---|
| `aws/vpc/`, `aws/ec2/`, `aws/oidc-providers/` | live |
| `aws/jenkins/`, `azure/jenkins/`, `gcp/jenkins/` | live mirrors |
| Everything else (eks, elk, github-runners, prometheus, …) | 0-byte stubs reserved for future work |

Cloud accounts are themselves the tenant boundary; subdividing within is
unnecessary.

## Adding a new chart

```bash
NAME=elasticsearch

# Decide flavour:
# A) values-template only (meta-module wraps it):
mkdir -p on-prem/helm/charts/${NAME}/templates
$EDITOR on-prem/helm/charts/${NAME}/values.yml.tmpl

# B) self-contained (richer logic — own main.tf):
mkdir -p on-prem/helm/charts/${NAME}/templates
$EDITOR on-prem/helm/charts/${NAME}/{main,variables,outputs}.tf
```

Then add a corresponding terragrunt leaf in
`devops-terragrunt-environments/on-prem/<tenant>/<env>/${NAME}/terragrunt.hcl`.

## Adding a new tenant

`mkdir` in three places:
- `devops-terragrunt-environments/on-prem/<tenant>/{backend,kube-config,vault-config}.hcl`
- `devops-terragrunt-environments/on-prem/<tenant>/{dev,local}/<resource>/terragrunt.hcl` (mirror existing tenant)
- `devops-terragrunt-environments/deployments/on-prem/<tenant>/envs/<env>/*.bash[.example]`

Plus per-tenant ansible-vault password file at `~/.config/ansible-vault/<tenant>`.

**No changes in this repo.** That's the whole point.

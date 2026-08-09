# ── Auth method: Kubernetes (in-cluster pods / ESO) ──────────────────────────
# ADDITIVE to the byte-compatible AppRole/userpass surface — new resource addresses only, so a
# vault-roles/vault-auths migration is untouched. Enabled ONLY when var.k8s_auth is non-empty.
#
# How it works: a pod presents its ServiceAccount JWT; Vault calls the k8s TokenReview API to
# validate it, matches the (namespace, service_account) binding to a role, and issues a Vault
# token carrying that role's policies. Preferred over AppRole for in-cluster clients because no
# secret_id ever lands in git or a K8s Secret — the pod's projected SA token IS the credential.
#
# PREREQUISITE — Vault's OWN ServiceAccount must be allowed to call TokenReview. The
# hashicorp/vault Helm chart binds it to the `system:auth-delegator` ClusterRole by default
# (server.authDelegator.enabled = true). With token_reviewer_jwt / kubernetes_ca_cert left empty
# and disable_local_ca_jwt at its default (false), Vault uses its own pod SA token + the
# in-cluster CA under /var/run/secrets/kubernetes.io/serviceaccount/ to reach the API — so there
# is nothing to wire here. If `terragrunt apply` errors with a TokenReview 403, verify:
#   kubectl get clusterrolebinding | grep vault   # must bind the vault SA to system:auth-delegator

resource "vault_auth_backend" "kubernetes" {
  count = length(var.k8s_auth) > 0 ? 1 : 0
  type  = "kubernetes"
  # Mount path is configurable so a SHARED Vault can host more than one env's k8s auth backend
  # without colliding. Default "kubernetes" keeps existing envs byte-compatible; a prod env on a
  # shared cluster sets "kubernetes-prod" (local already owns "kubernetes"). ESO SecretStores must
  # set auth.kubernetes.mountPath to match this path.
  path = var.k8s_auth_path
}

resource "vault_kubernetes_auth_backend_config" "this" {
  count           = length(var.k8s_auth) > 0 ? 1 : 0
  backend         = vault_auth_backend.kubernetes[0].path
  kubernetes_host = var.k8s_host
  # token_reviewer_jwt / kubernetes_ca_cert intentionally omitted → Vault uses its own in-cluster
  # SA token + CA (the "local" review method). Requires the vault SA → system:auth-delegator
  # (default in the hashicorp/vault chart — see the PREREQUISITE note above).
}

# One policy per app — same rule shape + shared template as roles.tf, so rendering is identical:
# a policy.path of "trainee/*" becomes  path "<kv_mount>/data/<path_root>/trainee/*"  (e.g.
# "fitmate/data/local/trainee/*"). Reusing local.kv_mount / local.path_root keeps org/env layout
# in lockstep with the AppRole policies.
resource "vault_policy" "k8s" {
  for_each = var.k8s_auth
  name     = each.key
  policy = fileexists(local.policies_tmp_file) ? templatefile(local.policies_tmp_file, {
    mount_path = local.kv_mount
    path_root  = local.path_root
    policies   = each.value.policies
  }) : ""
}

# One k8s auth role per app, bound to its (namespace, service account). token_policies = [name]
# attaches the policy above. ESO re-authenticates automatically when the token TTL lapses.
resource "vault_kubernetes_auth_backend_role" "this" {
  for_each                         = var.k8s_auth
  backend                          = vault_auth_backend.kubernetes[0].path
  role_name                        = each.key
  bound_service_account_names      = each.value.service_accounts
  bound_service_account_namespaces = each.value.namespaces
  token_policies                   = [each.key]
  token_ttl                        = 3600 # 1h; ESO re-auths on expiry

  depends_on = [vault_policy.k8s, vault_kubernetes_auth_backend_config.this]
}

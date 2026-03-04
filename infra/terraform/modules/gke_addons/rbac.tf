# NOTE: Intentionally destroyed in Mar 2026 for cost control.
# Keep definition for later re-provisioning.
resource "kubernetes_cluster_role_binding_v1" "gha_cluster_admin" {
  metadata {
    name = "gha-ci-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = var.ci_service_account_email
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_namespace_v1" "wikistream" {
  metadata {
    name = var.app_namespace
  }
}

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version

  set = [{
    name  = "installCRDs"
    value = "true"
  }]
}

resource "kubernetes_namespace_v1" "flink_operator" {
  metadata {
    name = "flink-operator"
  }
}

resource "helm_release" "flink_operator" {
  name      = "flink-kubernetes-operator"
  namespace = kubernetes_namespace_v1.flink_operator.metadata[0].name

  repository = "https://downloads.apache.org/flink/flink-kubernetes-operator-${var.flink_operator_version}/"
  chart      = "flink-kubernetes-operator"

  depends_on = [helm_release.cert_manager]

  set = [{
    name  = "watchNamespaces"
    value = "{${var.app_namespace}}"
  }]
}

data "http" "gcp_provider_yaml" {
  url = "https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/v1.11.0/deploy/provider-gcp-plugin.yaml"
}

resource "helm_release" "secrets_store_csi" {
  count      = 0
  name       = "csi-secrets-store"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.5"

  set = [{
    name  = "syncSecret.enabled"
    value = "true"
    }, {
    name  = "enableSecretRotation"
    value = "true"
    }, {
    name  = "installCRDs"
    value = "true"
  }]
}

resource "kubectl_manifest" "secrets_store_gcp_provider" {
  count      = 0
  yaml_body  = data.http.gcp_provider_yaml.response_body
  depends_on = [helm_release.secrets_store_csi]
}

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

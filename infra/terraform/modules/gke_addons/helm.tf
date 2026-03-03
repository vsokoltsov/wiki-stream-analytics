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


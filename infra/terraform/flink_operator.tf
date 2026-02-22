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

  # Wait for cert-manager before enabling webhook
  depends_on = [helm_release.cert_manager]

  # Optional: watch only app namespace (удобнее и безопаснее)
  set = [{
    name  = "watchNamespaces"
    value = "{${var.app_namespace}}"
  }]

  # Webhook enabled by default; keep it enabled
  # (If you want to disable: set webhook.create=false)
}
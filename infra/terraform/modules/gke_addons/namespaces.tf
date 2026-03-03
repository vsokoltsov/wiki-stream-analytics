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

resource "kubernetes_namespace_v1" "flink_operator" {
  metadata {
    name = "flink-operator"
  }
}


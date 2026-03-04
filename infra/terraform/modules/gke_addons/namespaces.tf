resource "kubernetes_namespace_v1" "wikistream" {
  metadata {
    name = var.app_namespace
  }

  timeouts {
    delete = "30m"
  }
}

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }

  timeouts {
    delete = "30m"
  }
}

resource "kubernetes_namespace_v1" "flink_operator" {
  metadata {
    name = "flink-operator"
  }

  timeouts {
    delete = "30m"
  }
}

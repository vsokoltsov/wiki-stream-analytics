resource "kubernetes_namespace_v1" "wikistream" {
  metadata {
    name = "wikistream"
  }
}
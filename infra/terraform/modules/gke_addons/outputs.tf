output "app_namespace" {
  value = kubernetes_namespace_v1.wikistream.metadata[0].name
}

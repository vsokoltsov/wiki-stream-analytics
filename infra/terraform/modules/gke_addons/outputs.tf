output "app_namespace" {
  value = kubernetes_namespace_v1.wikistream.metadata[0].name
}

output "flink_public_ip" {
  value = google_compute_address.flink_ip.address
}

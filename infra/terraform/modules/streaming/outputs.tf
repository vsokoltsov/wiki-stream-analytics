output "kafka_cluster_name" {
  value = google_managed_kafka_cluster.kafka.name
}

output "producer_service_account_email" {
  value = google_service_account.producer_sa.email
}

output "processing_service_account_email" {
  value = google_service_account.processing_sa.email
}

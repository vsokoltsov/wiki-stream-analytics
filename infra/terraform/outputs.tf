output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "ci_service_account_email" {
  value = google_service_account.ci.email
}

output "cloudbuild_staging_bucket_name" {
  value = google_storage_bucket.cloudbuild_staging.name
}

output "kafka_cluster_name" {
  value = google_managed_kafka_cluster.kafka.name
}

output "region" {
  value = var.region
}
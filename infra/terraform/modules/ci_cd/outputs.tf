output "ci_service_account_email" {
  value = google_service_account.ci.email
}

output "ci_service_account_name" {
  value = google_service_account.ci.name
}

output "cloudbuild_runner_service_account_email" {
  value = google_service_account.cloudbuild_runner.email
}

output "cloudbuild_runner_service_account_name" {
  value = google_service_account.cloudbuild_runner.name
}

output "cloudbuild_staging_bucket_name" {
  value = google_storage_bucket.cloudbuild_staging.name
}

output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

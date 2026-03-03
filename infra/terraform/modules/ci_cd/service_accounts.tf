resource "google_service_account" "ci" {
  account_id   = var.ci_sa_account_id
  display_name = "GitHub Actions CI"
}

resource "google_service_account" "cloudbuild_runner" {
  account_id   = "cloudbuild-runner"
  display_name = "Cloud Build Runner"
}

resource "google_service_account_iam_member" "gha_actas_runner" {
  service_account_id = google_service_account.cloudbuild_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.ci.email}"
}


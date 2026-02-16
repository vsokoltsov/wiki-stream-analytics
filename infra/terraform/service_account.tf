resource "google_service_account" "ci" {
  account_id   = var.ci_sa_account_id   # e.g. "gha-ci"
  display_name = "GitHub Actions CI"
}

resource "google_service_account" "cloudbuild_runner" {
  account_id   = "cloudbuild-runner"
  display_name = "Cloud Build Runner"
}
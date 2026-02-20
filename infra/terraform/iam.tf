data "google_project" "this" {
  project_id = var.project_id
}

locals {
  gha_ci_sa = "serviceAccount:gha-ci@${var.project_id}.iam.gserviceaccount.com"
  cloudbuild_sa_email = "${data.google_project.this.number}@cloudbuild.gserviceaccount.com"
  
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = var.wif_pool_id           # e.g. "github"
  display_name              = "GitHub Actions Pool"
  description               = "OIDC federation for GitHub Actions"
  disabled                  = false
}

# 2) Workload Identity Provider (OIDC)
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_provider_id              # e.g. "github-provider"
  display_name                       = "GitHub OIDC Provider"
  description                        = "Trust GitHub OIDC tokens"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Map GitHub OIDC claims -> attributes you can use in conditions / IAM bindings
  attribute_mapping = {
    "google.subject"           = "assertion.sub"
    "attribute.repository"     = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"            = "assertion.ref"
    "attribute.actor"          = "assertion.actor"
  }

  # Lock to a specific repo (recommended)
  attribute_condition = "assertion.repository == \"${var.github_owner}/${var.github_repo}\""
}

resource "google_service_account_iam_member" "wif_user" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_owner}/${var.github_repo}"
}

resource "google_project_iam_member" "ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_project_iam_member" "gha_serviceusage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = local.gha_ci_sa
}

# Allow submitting Cloud Build builds
resource "google_project_iam_member" "gha_cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = local.gha_ci_sa
}

# GitHub Actions SA can upload sources for Cloud Build
resource "google_storage_bucket_iam_member" "gha_staging_object_admin" {
  bucket = google_storage_bucket.cloudbuild_staging.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_storage_bucket_iam_member" "gha_ci_object_admin" {
  bucket = google_storage_bucket.cloudbuild_staging.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_storage_bucket_iam_member" "gha_ci_bucket_viewer" {
  bucket = google_storage_bucket.cloudbuild_staging.name
  role   = "roles/storage.bucketViewer"
  member = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_project_iam_member" "runner_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloudbuild_runner.email}"
}

resource "google_project_iam_member" "runner_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild_runner.email}"
}

resource "google_storage_bucket_iam_member" "cloudbuild_runner_object_viewer" {
  bucket = google_storage_bucket.cloudbuild_staging.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cloudbuild_runner.email}"
}

# Let gha-ci tell Cloud Build to run as cloudbuild-runner
resource "google_service_account_iam_member" "gha_actas_runner" {
  service_account_id = google_service_account.cloudbuild_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_project_iam_member" "producer_kafka" {
  project = var.project_id
  role    = "roles/managedkafka.client"
  member  = "serviceAccount:${google_service_account.producer_sa.email}"
}

resource "google_service_account_iam_member" "producer_wi" {
  service_account_id = google_service_account.producer_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member = "serviceAccount:${var.project_id}.svc.id.goog[producer/producer-sa]"
}
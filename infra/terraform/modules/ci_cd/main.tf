data "google_project" "this" {
  project_id = var.project_id
}

locals {
  gha_ci_sa           = "serviceAccount:${google_service_account.ci.email}"
  cloudbuild_sa_email = "${data.google_project.this.number}@cloudbuild.gserviceaccount.com"
}

resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "wiki-stream-analytics"
  description   = "Docker images for wiki-stream-analytics"
  format        = "DOCKER"
}

resource "google_storage_bucket" "cloudbuild_staging" {
  name          = "${var.project_id}-cloudbuild-staging"
  location      = "EU"
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_service_account" "ci" {
  account_id   = var.ci_sa_account_id
  display_name = "GitHub Actions CI"
}

resource "google_service_account" "cloudbuild_runner" {
  account_id   = "cloudbuild-runner"
  display_name = "Cloud Build Runner"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = var.wif_pool_id
  display_name              = "GitHub Actions Pool"
  description               = "OIDC federation for GitHub Actions"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_provider_id
  display_name                       = "GitHub OIDC Provider"
  description                        = "Trust GitHub OIDC tokens"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
    "attribute.actor"            = "assertion.actor"
  }

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

resource "google_project_iam_member" "gha_cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gha_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gha_iam_security_reviewer" {
  project = var.project_id
  role    = "roles/iam.securityReviewer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gha_service_account_viewer" {
  project = var.project_id
  role    = "roles/iam.serviceAccountViewer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gha_workload_identity_pool_viewer" {
  project = var.project_id
  role    = "roles/iam.workloadIdentityPoolViewer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gha_managedkafka_viewer" {
  project = var.project_id
  role    = "roles/managedkafka.viewer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gha_secretmanager_viewer" {
  project = var.project_id
  role    = "roles/secretmanager.viewer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gha_pubsub_viewer" {
  project = var.project_id
  role    = "roles/pubsub.viewer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gha_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = local.gha_ci_sa
}

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

resource "google_service_account_iam_member" "gha_actas_runner" {
  service_account_id = google_service_account.cloudbuild_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.ci.email}"
}

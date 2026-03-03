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


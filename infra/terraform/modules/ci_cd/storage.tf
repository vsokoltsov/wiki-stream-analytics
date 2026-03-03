resource "google_storage_bucket" "cloudbuild_staging" {
  name          = "${var.project_id}-cloudbuild-staging"
  location      = "EU"
  force_destroy = true

  uniform_bucket_level_access = true
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

resource "google_storage_bucket_iam_member" "cloudbuild_runner_object_viewer" {
  bucket = google_storage_bucket.cloudbuild_staging.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cloudbuild_runner.email}"
}


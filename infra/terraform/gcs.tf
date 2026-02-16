resource "google_storage_bucket" "cloudbuild_staging" {
  name          = "${var.project_id}-cloudbuild-staging"
  location      = "EU"
  force_destroy = true

  uniform_bucket_level_access = true
}
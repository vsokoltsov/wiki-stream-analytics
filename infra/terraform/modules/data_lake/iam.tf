resource "google_storage_bucket_iam_member" "processing_gcs_object_admin" {
  bucket = google_storage_bucket.datalake.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.processing_service_account_email}"
}

resource "google_storage_bucket_iam_member" "processing_flink_state_object_admin" {
  bucket = google_storage_bucket.flink_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.processing_service_account_email}"
}


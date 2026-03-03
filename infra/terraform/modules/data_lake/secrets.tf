resource "google_secret_manager_secret" "gcs_bucket" {
  secret_id = "gcs_bucket"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gcs_bucket_v1" {
  secret      = google_secret_manager_secret.gcs_bucket.id
  secret_data = google_storage_bucket.datalake.name
}

resource "google_secret_manager_secret" "flink_state_bucket" {
  secret_id = "flink_state_bucket"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "flink_state_bucket_v1" {
  secret      = google_secret_manager_secret.flink_state_bucket.id
  secret_data = google_storage_bucket.flink_state.name
}


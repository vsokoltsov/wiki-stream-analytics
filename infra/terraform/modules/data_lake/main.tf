resource "google_storage_bucket" "datalake" {
  name                        = var.bucket_name
  location                    = var.location
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_pubsub_topic" "datalake_objects" {
  name = "${var.name_prefix}-datalake-objects"
}

resource "google_pubsub_subscription" "datalake_objects_sub" {
  name  = "${var.name_prefix}-datalake-objects-sub"
  topic = google_pubsub_topic.datalake_objects.name

  ack_deadline_seconds = 30
}

data "google_storage_project_service_account" "gcs" {
  project = var.project_id
}

resource "google_pubsub_topic_iam_member" "allow_gcs_publish" {
  topic  = google_pubsub_topic.datalake_objects.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

resource "google_storage_notification" "to_pubsub" {
  bucket         = google_storage_bucket.datalake.name
  topic          = google_pubsub_topic.datalake_objects.id
  payload_format = "JSON_API_V1"

  event_types = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_member.allow_gcs_publish]
}

resource "google_storage_bucket_iam_member" "processing_gcs_object_admin" {
  bucket = google_storage_bucket.datalake.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.processing_service_account_email}"
}

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

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


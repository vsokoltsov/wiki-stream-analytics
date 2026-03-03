resource "google_storage_notification" "to_pubsub" {
  bucket         = google_storage_bucket.datalake.name
  topic          = google_pubsub_topic.datalake_objects.id
  payload_format = "JSON_API_V1"

  event_types = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_member.allow_gcs_publish]
}


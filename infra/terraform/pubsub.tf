resource "google_pubsub_topic" "datalake_objects" {
  name = "${var.name_prefix}-datalake-objects"
}

resource "google_pubsub_subscription" "datalake_objects_sub" {
  name  = "${var.name_prefix}-datalake-objects-sub"
  topic = google_pubsub_topic.datalake_objects.name

  ack_deadline_seconds = 30
}

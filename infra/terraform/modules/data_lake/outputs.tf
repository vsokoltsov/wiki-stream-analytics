output "bucket_name" {
  value = google_storage_bucket.datalake.name
}

output "flink_state_bucket_name" {
  value = google_storage_bucket.flink_state.name
}

output "pubsub_topic_name" {
  value = google_pubsub_topic.datalake_objects.name
}

output "pubsub_subscription_name" {
  value = google_pubsub_subscription.datalake_objects_sub.name
}

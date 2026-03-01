resource "google_storage_bucket" "cloudbuild_staging" {
  name          = "${var.project_id}-cloudbuild-staging"
  location      = "EU"
  force_destroy = true

  uniform_bucket_level_access = true
}

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


resource "google_storage_notification" "to_pubsub" {
  bucket         = google_storage_bucket.datalake.name
  topic          = google_pubsub_topic.datalake_objects.id
  payload_format = "JSON_API_V1"

  event_types = ["OBJECT_FINALIZE"]

  depends_on = [
    google_pubsub_topic_iam_member.allow_gcs_publish
  ]
}

resource "google_storage_bucket" "dataflow_staging" {
  name                        = "${var.project_id}-dataflow-staging"
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition { age = 7 }
    action { type = "Delete" }
  }
}

resource "google_storage_bucket" "dataflow_temp" {
  name                        = "${var.project_id}-dataflow-temp"
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition { age = 7 }
    action { type = "Delete" }
  }
}

resource "google_storage_bucket" "dataflow_templates" {
  name                        = "${var.project_id}-dataflow-templates"
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition { age = 30 }
    action { type = "Delete" }
  }
}
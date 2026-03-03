resource "google_bigquery_dataset" "raw" {
  dataset_id = "wikistream_raw"
  location   = var.location
}

resource "google_bigquery_table" "events" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  table_id   = "recentchanges"

  deletion_protection      = true
  require_partition_filter = true

  schema = jsonencode([
    { name = "event_ts", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "wiki", type = "STRING", mode = "NULLABLE" },
    { name = "type", type = "STRING", mode = "NULLABLE" },
    { name = "user_name", type = "STRING", mode = "NULLABLE" },
    { name = "bot", type = "BOOL", mode = "NULLABLE" },
    { name = "title", type = "STRING", mode = "NULLABLE" },
    { name = "namespace_id", type = "INT64", mode = "NULLABLE" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "event_ts"
  }

  clustering = ["wiki", "namespace_id"]

  lifecycle {
    ignore_changes = [schema]
  }
}

resource "google_bigquery_dataset" "wiki_analytics" {
  project    = var.project_id
  dataset_id = "wikistream_analytics"
  location   = "EU"
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

resource "google_service_account" "dataflow_sa" {
  account_id   = "dataflow-wikistream-sa"
  display_name = "Dataflow SA for wikistream pipeline"
}

resource "google_service_account" "dbt_sa" {
  account_id   = "dbt-wikistream-sa"
  display_name = "DBT SA for wikistream analytics"
}

resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_project_iam_member" "bq_jobuser" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "bq_data_editor" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_storage_bucket_iam_member" "datalake_read" {
  bucket = var.datalake_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_storage_bucket_iam_member" "staging_rw" {
  bucket = google_storage_bucket.dataflow_staging.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_storage_bucket_iam_member" "temp_rw" {
  bucket = google_storage_bucket.dataflow_temp.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_storage_bucket_iam_member" "templates_rw" {
  bucket = google_storage_bucket.dataflow_templates.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_storage_bucket_iam_member" "cloudbuild_runner_templates_object_admin" {
  bucket = google_storage_bucket.dataflow_templates.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.cloudbuild_runner_email}"
}

resource "google_project_iam_member" "gha_dataflow_developer" {
  project = var.project_id
  role    = "roles/dataflow.developer"
  member  = "serviceAccount:${var.ci_service_account_email}"
}

resource "google_storage_bucket_iam_member" "gha_ci_templates_object_viewer" {
  bucket = google_storage_bucket.dataflow_templates.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.ci_service_account_email}"
}

resource "google_service_account_iam_member" "gha_actas_dataflow_sa" {
  service_account_id = google_service_account.dataflow_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.ci_service_account_email}"
}

resource "google_project_iam_member" "dataflow_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_pubsub_subscription_iam_member" "dataflow_subscriber" {
  subscription = var.pubsub_subscription_name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_pubsub_subscription_iam_member" "dataflow_subscription_viewer" {
  subscription = var.pubsub_subscription_name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_write_analytics" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.wiki_analytics.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dbt_sa.email}"
}

resource "google_bigquery_dataset_iam_member" "dbt_read_raw" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.dbt_sa.email}"
}

resource "google_project_iam_member" "dbt_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt_sa.email}"
}

resource "google_project_iam_member" "ci_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${var.ci_service_account_email}"
}

resource "google_bigquery_dataset_iam_member" "ci_raw_viewer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.ci_service_account_email}"
}

resource "google_bigquery_dataset_iam_member" "ci_marts_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.wiki_analytics.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.ci_service_account_email}"
}

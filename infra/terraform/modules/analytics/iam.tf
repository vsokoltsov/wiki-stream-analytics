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


data "google_project" "this" {
  project_id = var.project_id
}

locals {
  gha_ci_sa           = "serviceAccount:${module.ci_cd.ci_service_account_email}"
  cloudbuild_sa_email = "${data.google_project.this.number}@cloudbuild.gserviceaccount.com"

}

# Allow CI to read cluster metadata (needed for get-credentials)
resource "google_project_iam_member" "gha_gke_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = local.gha_ci_sa
}

# Needed to call container API + generate kubeconfig credentials
# (in practice, this role avoids a bunch of "permission denied" edges)
resource "google_project_iam_member" "gha_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "producer_kafka" {
  project = var.project_id
  role    = "roles/managedkafka.client"
  member  = "serviceAccount:${google_service_account.producer_sa.email}"
}


resource "google_project_iam_member" "processing_kafka" {
  project = var.project_id
  role    = "roles/managedkafka.client"
  member  = "serviceAccount:${google_service_account.processing_sa.email}"
}

resource "google_service_account_iam_member" "producer_wi" {
  service_account_id = google_service_account.producer_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[wikistream/producer-sa]"
}

resource "google_service_account_iam_member" "processing_wi" {
  service_account_id = google_service_account.processing_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[wikistream/processing-sa]"
}

resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "producer_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.producer_sa.email}"
}

resource "google_project_iam_member" "processing_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.processing_sa.email}"
}

data "google_storage_project_service_account" "gcs" {
  project    = var.project_id
  depends_on = [module.bootstrap]
}

resource "google_pubsub_topic_iam_member" "allow_gcs_publish" {
  topic  = google_pubsub_topic.datalake_objects.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"

  depends_on = [module.bootstrap]
}

resource "google_storage_bucket_iam_member" "processing_gcs_object_admin" {
  bucket = google_storage_bucket.datalake.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.processing_sa.email}"
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
  dataset_id = "wikistream_raw"
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_storage_bucket_iam_member" "datalake_read" {
  bucket = "wikistream-datalake"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

# staging/temp/templates rw
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
  member = "serviceAccount:${module.ci_cd.cloudbuild_runner_service_account_email}"
}

resource "google_project_iam_member" "gha_dataflow_developer" {
  project = var.project_id
  role    = "roles/dataflow.developer"
  member  = "serviceAccount:${module.ci_cd.ci_service_account_email}"
}

resource "google_storage_bucket_iam_member" "gha_ci_templates_object_viewer" {
  bucket = google_storage_bucket.dataflow_templates.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.ci_cd.ci_service_account_email}"
}

resource "google_service_account_iam_member" "gha_actas_dataflow_sa" {
  service_account_id = google_service_account.dataflow_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.ci_cd.ci_service_account_email}"
}

resource "google_project_iam_member" "dataflow_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_pubsub_subscription_iam_member" "dataflow_subscriber" {
  subscription = google_pubsub_subscription.datalake_objects_sub.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

resource "google_pubsub_subscription_iam_member" "dataflow_subscription_viewer" {
  subscription = google_pubsub_subscription.datalake_objects_sub.name
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
  member  = "serviceAccount:${module.ci_cd.ci_service_account_email}"
}

resource "google_bigquery_dataset_iam_member" "ci_raw_viewer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.raw.dataset_id

  role   = "roles/bigquery.dataViewer"
  member = "serviceAccount:${module.ci_cd.ci_service_account_email}"
}

resource "google_bigquery_dataset_iam_member" "ci_marts_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.wiki_analytics.dataset_id

  role   = "roles/bigquery.dataEditor"
  member = "serviceAccount:${module.ci_cd.ci_service_account_email}"
}

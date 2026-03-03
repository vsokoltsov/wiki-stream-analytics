output "workload_identity_provider" {
  value = module.ci_cd.workload_identity_provider
}

output "ci_service_account_email" {
  value = module.ci_cd.ci_service_account_email
}

output "cloudbuild_staging_bucket_name" {
  value = module.ci_cd.cloudbuild_staging_bucket_name
}

output "kafka_cluster_name" {
  value = google_managed_kafka_cluster.kafka.name
}

output "region" {
  value = var.region
}

output "bucket_name" {
  value = google_storage_bucket.datalake.name
}

output "pubsub_topic" {
  value = google_pubsub_topic.datalake_objects.name
}

output "pubsub_subscription" {
  value = google_pubsub_subscription.datalake_objects_sub.name
}

output "flink_public_ip" {
  value = google_compute_address.flink_ip.address
}

output "bq_dataset" {
  description = "BigQuery dataset identifiers"
  value = {
    dataset_id = google_bigquery_dataset.raw.dataset_id
    project_id = google_bigquery_dataset.raw.project
    location   = google_bigquery_dataset.raw.location
    self_link  = google_bigquery_dataset.raw.self_link
  }
}

output "bq_table" {
  description = "BigQuery table identifiers"
  value = {
    table_id   = google_bigquery_table.events.table_id
    dataset_id = google_bigquery_table.events.dataset_id
    project_id = google_bigquery_table.events.project
    self_link  = google_bigquery_table.events.self_link
  }
}

output "bq_table_fqn" {
  description = "Fully-qualified table name: project.dataset.table"
  value       = "${google_bigquery_table.events.project}.${google_bigquery_table.events.dataset_id}.${google_bigquery_table.events.table_id}"
}

output "bq_table_legacy_sql" {
  description = "Legacy SQL table reference: project:dataset.table"
  value       = "${google_bigquery_table.events.project}:${google_bigquery_table.events.dataset_id}.${google_bigquery_table.events.table_id}"
}

output "bq_destination_table_for_jobs" {
  description = "Convenient value to pass into ingestion pipeline / load jobs"
  value = {
    fqn      = "${google_bigquery_table.events.project}.${google_bigquery_table.events.dataset_id}.${google_bigquery_table.events.table_id}"
    dataset  = google_bigquery_table.events.dataset_id
    table    = google_bigquery_table.events.table_id
    project  = google_bigquery_table.events.project
    location = google_bigquery_dataset.raw.location
  }
}

output "dataflow_staging_bucket_name" {
  description = "GCS bucket name for Dataflow staging files"
  value       = google_storage_bucket.dataflow_staging.name
}

output "dataflow_temp_bucket_name" {
  description = "GCS bucket name for Dataflow temp files"
  value       = google_storage_bucket.dataflow_temp.name
}

output "dataflow_templates_bucket_name" {
  description = "GCS bucket name for Dataflow flex templates"
  value       = google_storage_bucket.dataflow_templates.name
}

output "dataflow_staging_uri" {
  description = "gs:// URI to Dataflow staging bucket"
  value       = "gs://${google_storage_bucket.dataflow_staging.name}"
}

output "dataflow_temp_uri" {
  description = "gs:// URI to Dataflow temp bucket"
  value       = "gs://${google_storage_bucket.dataflow_temp.name}"
}

output "dataflow_templates_uri" {
  description = "gs:// URI to Dataflow templates bucket"
  value       = "gs://${google_storage_bucket.dataflow_templates.name}"
}

# Часто удобно сразу отдавать дефолтные папки
output "dataflow_staging_location" {
  description = "Default staging location path"
  value       = "gs://${google_storage_bucket.dataflow_staging.name}/staging"
}

output "dataflow_temp_location" {
  description = "Default temp location path"
  value       = "gs://${google_storage_bucket.dataflow_temp.name}/tmp"
}

output "dataflow_template_dir" {
  description = "Default folder for flex template specs"
  value       = "gs://${google_storage_bucket.dataflow_templates.name}/templates"
}

output "dataflow_worker_sa_email" {
  description = "Dataflow worker service account email"
  value       = google_service_account.dataflow_sa.email
}

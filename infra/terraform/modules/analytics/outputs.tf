output "raw_dataset" {
  value = {
    dataset_id = google_bigquery_dataset.raw.dataset_id
    project_id = google_bigquery_dataset.raw.project
    location   = google_bigquery_dataset.raw.location
    self_link  = google_bigquery_dataset.raw.self_link
  }
}

output "events_table" {
  value = {
    table_id   = google_bigquery_table.events.table_id
    dataset_id = google_bigquery_table.events.dataset_id
    project_id = google_bigquery_table.events.project
    self_link  = google_bigquery_table.events.self_link
  }
}

output "events_table_fqn" {
  value = "${google_bigquery_table.events.project}.${google_bigquery_table.events.dataset_id}.${google_bigquery_table.events.table_id}"
}

output "events_table_legacy_sql" {
  value = "${google_bigquery_table.events.project}:${google_bigquery_table.events.dataset_id}.${google_bigquery_table.events.table_id}"
}

output "bq_destination_table_for_jobs" {
  value = {
    fqn      = "${google_bigquery_table.events.project}.${google_bigquery_table.events.dataset_id}.${google_bigquery_table.events.table_id}"
    dataset  = google_bigquery_table.events.dataset_id
    table    = google_bigquery_table.events.table_id
    project  = google_bigquery_table.events.project
    location = google_bigquery_dataset.raw.location
  }
}

output "dataflow_staging_bucket_name" {
  value = google_storage_bucket.dataflow_staging.name
}

output "dataflow_temp_bucket_name" {
  value = google_storage_bucket.dataflow_temp.name
}

output "dataflow_templates_bucket_name" {
  value = google_storage_bucket.dataflow_templates.name
}

output "dataflow_staging_uri" {
  value = "gs://${google_storage_bucket.dataflow_staging.name}"
}

output "dataflow_temp_uri" {
  value = "gs://${google_storage_bucket.dataflow_temp.name}"
}

output "dataflow_templates_uri" {
  value = "gs://${google_storage_bucket.dataflow_templates.name}"
}

output "dataflow_staging_location" {
  value = "gs://${google_storage_bucket.dataflow_staging.name}/staging"
}

output "dataflow_temp_location" {
  value = "gs://${google_storage_bucket.dataflow_temp.name}/tmp"
}

output "dataflow_template_dir" {
  value = "gs://${google_storage_bucket.dataflow_templates.name}/templates"
}

output "dataflow_worker_sa_email" {
  value = google_service_account.dataflow_sa.email
}

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
  value = module.streaming.kafka_cluster_name
}

output "region" {
  value = var.region
}

output "bucket_name" {
  value = module.data_lake.bucket_name
}

output "pubsub_topic" {
  value = module.data_lake.pubsub_topic_name
}

output "pubsub_subscription" {
  value = module.data_lake.pubsub_subscription_name
}

output "flink_public_ip" {
  value = module.gke_addons.flink_public_ip
}

output "bq_dataset" {
  description = "BigQuery dataset identifiers"
  value       = module.analytics.raw_dataset
}

output "bq_table" {
  description = "BigQuery table identifiers"
  value       = module.analytics.events_table
}

output "bq_table_fqn" {
  description = "Fully-qualified table name: project.dataset.table"
  value       = module.analytics.events_table_fqn
}

output "bq_table_legacy_sql" {
  description = "Legacy SQL table reference: project:dataset.table"
  value       = module.analytics.events_table_legacy_sql
}

output "bq_destination_table_for_jobs" {
  description = "Convenient value to pass into ingestion pipeline / load jobs"
  value       = module.analytics.bq_destination_table_for_jobs
}

output "dataflow_staging_bucket_name" {
  description = "GCS bucket name for Dataflow staging files"
  value       = module.analytics.dataflow_staging_bucket_name
}

output "dataflow_temp_bucket_name" {
  description = "GCS bucket name for Dataflow temp files"
  value       = module.analytics.dataflow_temp_bucket_name
}

output "dataflow_templates_bucket_name" {
  description = "GCS bucket name for Dataflow flex templates"
  value       = module.analytics.dataflow_templates_bucket_name
}

output "dataflow_staging_uri" {
  description = "gs:// URI to Dataflow staging bucket"
  value       = module.analytics.dataflow_staging_uri
}

output "dataflow_temp_uri" {
  description = "gs:// URI to Dataflow temp bucket"
  value       = module.analytics.dataflow_temp_uri
}

output "dataflow_templates_uri" {
  description = "gs:// URI to Dataflow templates bucket"
  value       = module.analytics.dataflow_templates_uri
}

# Часто удобно сразу отдавать дефолтные папки
output "dataflow_staging_location" {
  description = "Default staging location path"
  value       = module.analytics.dataflow_staging_location
}

output "dataflow_temp_location" {
  description = "Default temp location path"
  value       = module.analytics.dataflow_temp_location
}

output "dataflow_template_dir" {
  description = "Default folder for flex template specs"
  value       = module.analytics.dataflow_template_dir
}

output "dataflow_worker_sa_email" {
  description = "Dataflow worker service account email"
  value       = module.analytics.dataflow_worker_sa_email
}

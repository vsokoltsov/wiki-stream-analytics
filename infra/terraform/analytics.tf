module "analytics" {
  source = "./modules/analytics"

  project_id               = var.project_id
  location                 = var.location
  region                   = var.region
  dataflow_image_version   = var.image_version
  ci_service_account_email = module.ci_cd.ci_service_account_email
  cloudbuild_runner_email  = module.ci_cd.cloudbuild_runner_service_account_email
  pubsub_subscription_name = module.data_lake.pubsub_subscription_name
  datalake_bucket_name     = module.data_lake.bucket_name

  depends_on = [module.bootstrap]
}

moved {
  from = google_bigquery_dataset.raw
  to   = module.analytics.google_bigquery_dataset.raw
}

moved {
  from = google_bigquery_table.events
  to   = module.analytics.google_bigquery_table.events
}

moved {
  from = google_bigquery_dataset.wiki_analytics
  to   = module.analytics.google_bigquery_dataset.wiki_analytics
}

moved {
  from = google_storage_bucket.dataflow_staging
  to   = module.analytics.google_storage_bucket.dataflow_staging
}

moved {
  from = google_storage_bucket.dataflow_temp
  to   = module.analytics.google_storage_bucket.dataflow_temp
}

moved {
  from = google_storage_bucket.dataflow_templates
  to   = module.analytics.google_storage_bucket.dataflow_templates
}

moved {
  from = google_service_account.dataflow_sa
  to   = module.analytics.google_service_account.dataflow_sa
}

moved {
  from = google_service_account.dbt_sa
  to   = module.analytics.google_service_account.dbt_sa
}

moved {
  from = google_project_iam_member.dataflow_worker
  to   = module.analytics.google_project_iam_member.dataflow_worker
}

moved {
  from = google_project_iam_member.bq_jobuser
  to   = module.analytics.google_project_iam_member.bq_jobuser
}

moved {
  from = google_bigquery_dataset_iam_member.bq_data_editor
  to   = module.analytics.google_bigquery_dataset_iam_member.bq_data_editor
}

moved {
  from = google_storage_bucket_iam_member.datalake_read
  to   = module.analytics.google_storage_bucket_iam_member.datalake_read
}

moved {
  from = google_storage_bucket_iam_member.staging_rw
  to   = module.analytics.google_storage_bucket_iam_member.staging_rw
}

moved {
  from = google_storage_bucket_iam_member.temp_rw
  to   = module.analytics.google_storage_bucket_iam_member.temp_rw
}

moved {
  from = google_storage_bucket_iam_member.templates_rw
  to   = module.analytics.google_storage_bucket_iam_member.templates_rw
}

moved {
  from = google_storage_bucket_iam_member.cloudbuild_runner_templates_object_admin
  to   = module.analytics.google_storage_bucket_iam_member.cloudbuild_runner_templates_object_admin
}

moved {
  from = google_project_iam_member.gha_dataflow_developer
  to   = module.analytics.google_project_iam_member.gha_dataflow_developer
}

moved {
  from = google_storage_bucket_iam_member.gha_ci_templates_object_viewer
  to   = module.analytics.google_storage_bucket_iam_member.gha_ci_templates_object_viewer
}

moved {
  from = google_service_account_iam_member.gha_actas_dataflow_sa
  to   = module.analytics.google_service_account_iam_member.gha_actas_dataflow_sa
}

moved {
  from = google_project_iam_member.dataflow_ar_reader
  to   = module.analytics.google_project_iam_member.dataflow_ar_reader
}

moved {
  from = google_pubsub_subscription_iam_member.dataflow_subscriber
  to   = module.analytics.google_pubsub_subscription_iam_member.dataflow_subscriber
}

moved {
  from = google_pubsub_subscription_iam_member.dataflow_subscription_viewer
  to   = module.analytics.google_pubsub_subscription_iam_member.dataflow_subscription_viewer
}

moved {
  from = google_bigquery_dataset_iam_member.dbt_write_analytics
  to   = module.analytics.google_bigquery_dataset_iam_member.dbt_write_analytics
}

moved {
  from = google_bigquery_dataset_iam_member.dbt_read_raw
  to   = module.analytics.google_bigquery_dataset_iam_member.dbt_read_raw
}

moved {
  from = google_project_iam_member.dbt_job_user
  to   = module.analytics.google_project_iam_member.dbt_job_user
}

moved {
  from = google_project_iam_member.ci_bigquery_job_user
  to   = module.analytics.google_project_iam_member.ci_bigquery_job_user
}

moved {
  from = google_bigquery_dataset_iam_member.ci_raw_viewer
  to   = module.analytics.google_bigquery_dataset_iam_member.ci_raw_viewer
}

moved {
  from = google_bigquery_dataset_iam_member.ci_marts_editor
  to   = module.analytics.google_bigquery_dataset_iam_member.ci_marts_editor
}

variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "analytics_state_matches_current_stack" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = trimspace(file("terraform.tfstate")) != "" ? file("terraform.tfstate") : file("terraform.tfstate.backup")
  }

  assert {
    condition = toset(output.module_resources["module.analytics"]) == toset([
      "google_bigquery_dataset.raw",
      "google_bigquery_dataset.wiki_analytics",
      "google_bigquery_dataset_iam_member.bq_data_editor",
      "google_bigquery_dataset_iam_member.ci_marts_editor",
      "google_bigquery_dataset_iam_member.ci_raw_viewer",
      "google_bigquery_dataset_iam_member.dbt_read_raw",
      "google_bigquery_dataset_iam_member.dbt_write_analytics",
      "google_bigquery_table.events",
      "google_project_iam_member.bq_jobuser",
      "google_project_iam_member.ci_bigquery_job_user",
      "google_project_iam_member.dataflow_ar_reader",
      "google_project_iam_member.dataflow_worker",
      "google_project_iam_member.dbt_job_user",
      "google_project_iam_member.gha_dataflow_developer",
      "google_pubsub_subscription_iam_member.dataflow_subscriber",
      "google_pubsub_subscription_iam_member.dataflow_subscription_viewer",
      "google_service_account.dataflow_sa",
      "google_service_account.dbt_sa",
      "google_service_account_iam_member.gha_actas_dataflow_sa",
      "google_storage_bucket.dataflow_staging",
      "google_storage_bucket.dataflow_temp",
      "google_storage_bucket.dataflow_templates",
      "google_storage_bucket_iam_member.cloudbuild_runner_templates_object_admin",
      "google_storage_bucket_iam_member.datalake_read",
      "google_storage_bucket_iam_member.gha_ci_templates_object_viewer",
      "google_storage_bucket_iam_member.staging_rw",
      "google_storage_bucket_iam_member.temp_rw",
      "google_storage_bucket_iam_member.templates_rw",
    ])
    error_message = "analytics module resources no longer match the applied state."
  }

  assert {
    condition     = output.module_resource_attributes["module.analytics"]["google_bigquery_dataset.raw"].dataset_id == "wikistream_raw"
    error_message = "analytics raw dataset_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.analytics"]["google_bigquery_dataset.wiki_analytics"].dataset_id == "wikistream_analytics"
    error_message = "analytics marts dataset_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.analytics"]["google_bigquery_table.events"].table_id == "recentchanges"
    error_message = "analytics events table_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.analytics"]["google_bigquery_table.events"].require_partition_filter == true
    error_message = "analytics events table should require partition filters."
  }

  assert {
    condition     = output.module_resource_attributes["module.analytics"]["google_storage_bucket.dataflow_staging"].name == "wiki-stream-analytics-dataflow-staging"
    error_message = "analytics dataflow staging bucket name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.analytics"]["google_storage_bucket.dataflow_templates"].name == "wiki-stream-analytics-dataflow-templates"
    error_message = "analytics dataflow templates bucket name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.analytics"]["google_service_account.dataflow_sa"].account_id == "dataflow-wikistream-sa"
    error_message = "analytics Dataflow SA account_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.analytics"]["google_service_account.dbt_sa"].account_id == "dbt-wikistream-sa"
    error_message = "analytics DBT SA account_id drifted."
  }
}

variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "stack_outputs_match_current_state" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = file("terraform.tfstate")
  }

  assert {
    condition = toset(keys(output.outputs)) == toset([
      "bq_dataset",
      "bq_destination_table_for_jobs",
      "bq_table",
      "bq_table_fqn",
      "bq_table_legacy_sql",
      "bucket_name",
      "ci_service_account_email",
      "cloudbuild_staging_bucket_name",
      "dataflow_staging_bucket_name",
      "dataflow_staging_location",
      "dataflow_staging_uri",
      "dataflow_temp_bucket_name",
      "dataflow_temp_location",
      "dataflow_temp_uri",
      "dataflow_template_dir",
      "dataflow_templates_bucket_name",
      "dataflow_templates_uri",
      "dataflow_worker_sa_email",
      "flink_public_ip",
      "kafka_cluster_name",
      "pubsub_subscription",
      "pubsub_topic",
      "region",
      "workload_identity_provider",
    ])
    error_message = "Root outputs no longer match the applied state contract."
  }

  assert {
    condition     = output.outputs.bucket_name == "wikistream-datalake"
    error_message = "bucket_name output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.pubsub_topic == "wikistream-datalake-objects"
    error_message = "pubsub_topic output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.pubsub_subscription == "wikistream-datalake-objects-sub"
    error_message = "pubsub_subscription output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.region == "europe-west3"
    error_message = "region output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.bq_table_fqn == "wiki-stream-analytics.wikistream_raw.recentchanges"
    error_message = "bq_table_fqn output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.bq_table_legacy_sql == "wiki-stream-analytics:wikistream_raw.recentchanges"
    error_message = "bq_table_legacy_sql output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.cloudbuild_staging_bucket_name == "wiki-stream-analytics-cloudbuild-staging"
    error_message = "cloudbuild staging bucket output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.dataflow_staging_uri == "gs://wiki-stream-analytics-dataflow-staging"
    error_message = "dataflow_staging_uri output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.dataflow_temp_uri == "gs://wiki-stream-analytics-dataflow-temp"
    error_message = "dataflow_temp_uri output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.dataflow_templates_uri == "gs://wiki-stream-analytics-dataflow-templates"
    error_message = "dataflow_templates_uri output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.dataflow_staging_location == "gs://wiki-stream-analytics-dataflow-staging/staging"
    error_message = "dataflow_staging_location output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.dataflow_temp_location == "gs://wiki-stream-analytics-dataflow-temp/tmp"
    error_message = "dataflow_temp_location output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.dataflow_template_dir == "gs://wiki-stream-analytics-dataflow-templates/templates"
    error_message = "dataflow_template_dir output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.flink_public_ip == "34.40.47.43"
    error_message = "flink_public_ip output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.workload_identity_provider == "projects/418798255071/locations/global/workloadIdentityPools/github/providers/github-provider"
    error_message = "workload_identity_provider output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.ci_service_account_email == "gha-ci@wiki-stream-analytics.iam.gserviceaccount.com"
    error_message = "ci_service_account_email output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.kafka_cluster_name == "projects/wiki-stream-analytics/locations/europe-west3/clusters/wiki-kafka"
    error_message = "kafka_cluster_name output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.dataflow_worker_sa_email == "dataflow-wikistream-sa@wiki-stream-analytics.iam.gserviceaccount.com"
    error_message = "dataflow_worker_sa_email output drifted from the applied state."
  }

  assert {
    condition     = output.outputs.bq_dataset.dataset_id == "wikistream_raw"
    error_message = "bq_dataset.dataset_id drifted from the applied state."
  }

  assert {
    condition     = output.outputs.bq_table.table_id == "recentchanges"
    error_message = "bq_table.table_id drifted from the applied state."
  }
}

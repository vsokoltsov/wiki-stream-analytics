variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "data_lake_state_matches_current_stack" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = trimspace(file("terraform.tfstate")) != "" ? file("terraform.tfstate") : file("terraform.tfstate.backup")
  }

  assert {
    condition = (
      toset(output.module_resources["module.data_lake"]) == toset([
        "google_pubsub_subscription.datalake_objects_sub",
        "google_pubsub_topic.datalake_objects",
        "google_pubsub_topic_iam_member.allow_gcs_publish",
        "google_secret_manager_secret.gcs_bucket",
        "google_secret_manager_secret_version.gcs_bucket_v1",
        "google_storage_bucket.datalake",
        "google_storage_bucket_iam_member.processing_gcs_object_admin",
        "google_storage_notification.to_pubsub",
        "google_storage_project_service_account.gcs",
      ])
      ) || (
      toset(output.module_resources["module.data_lake"]) == toset([
        "google_pubsub_subscription.datalake_objects_sub",
        "google_pubsub_topic.datalake_objects",
        "google_pubsub_topic_iam_member.allow_gcs_publish",
        "google_secret_manager_secret.flink_state_bucket",
        "google_secret_manager_secret.gcs_bucket",
        "google_secret_manager_secret_version.flink_state_bucket_v1",
        "google_secret_manager_secret_version.gcs_bucket_v1",
        "google_storage_bucket.datalake",
        "google_storage_bucket.flink_state",
        "google_storage_bucket_iam_member.processing_flink_state_object_admin",
        "google_storage_bucket_iam_member.processing_gcs_object_admin",
        "google_storage_notification.to_pubsub",
        "google_storage_project_service_account.gcs",
      ])
    )
    error_message = "data_lake module resources no longer match either the pre-state-bucket or post-state-bucket applied state."
  }

  assert {
    condition     = output.module_resource_attributes["module.data_lake"]["google_storage_bucket.datalake"].name == "wikistream-datalake"
    error_message = "data_lake bucket name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.data_lake"]["google_storage_bucket.datalake"].location == "EU"
    error_message = "data_lake bucket location drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.data_lake"]["google_pubsub_topic.datalake_objects"].name == "wikistream-datalake-objects"
    error_message = "data_lake Pub/Sub topic name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.data_lake"]["google_pubsub_subscription.datalake_objects_sub"].name == "wikistream-datalake-objects-sub"
    error_message = "data_lake Pub/Sub subscription name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.data_lake"]["google_pubsub_subscription.datalake_objects_sub"].ack_deadline_seconds == 30
    error_message = "data_lake Pub/Sub subscription ack deadline drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.data_lake"]["google_secret_manager_secret.gcs_bucket"].secret_id == "gcs_bucket"
    error_message = "data_lake gcs_bucket secret_id drifted."
  }

  assert {
    condition     = try(output.module_resource_attributes["module.data_lake"]["google_storage_bucket.flink_state"].name, "wikistream-flink-state") == "wikistream-flink-state"
    error_message = "data_lake Flink state bucket name drifted."
  }

  assert {
    condition     = try(output.module_resource_attributes["module.data_lake"]["google_secret_manager_secret.flink_state_bucket"].secret_id, "flink_state_bucket") == "flink_state_bucket"
    error_message = "data_lake flink_state_bucket secret_id drifted."
  }
}

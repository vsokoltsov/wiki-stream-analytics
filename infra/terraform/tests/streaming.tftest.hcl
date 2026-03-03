variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "streaming_state_matches_current_stack" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = trimspace(file("terraform.tfstate")) != "" ? file("terraform.tfstate") : file("terraform.tfstate.backup")
  }

  assert {
    condition = toset(output.module_resources["module.streaming"]) == toset([
      "google_managed_kafka_cluster.kafka",
      "google_managed_kafka_topic.recentchange_raw",
      "google_project_iam_member.processing_kafka",
      "google_project_iam_member.processing_secret_accessor",
      "google_project_iam_member.producer_kafka",
      "google_project_iam_member.producer_secret_accessor",
      "google_secret_manager_secret.kafka_bootstrap",
      "google_secret_manager_secret.kafka_bootstrap_mtls",
      "google_secret_manager_secret.kafka_sasl_username",
      "google_secret_manager_secret.kafka_sasl_username_processing",
      "google_secret_manager_secret.wiki_user_agent",
      "google_secret_manager_secret_version.kafka_bootstrap_mtls_v1",
      "google_secret_manager_secret_version.kafka_bootstrap_v1",
      "google_secret_manager_secret_version.kafka_sasl_username_processing_v1",
      "google_secret_manager_secret_version.kafka_sasl_username_v1",
      "google_secret_manager_secret_version.wiki_user_agent_v1",
      "google_service_account.processing_sa",
      "google_service_account.producer_sa",
      "google_service_account_iam_member.processing_wi",
      "google_service_account_iam_member.producer_wi",
      "kubernetes_service_account_v1.processing",
      "kubernetes_service_account_v1.producer",
    ])
    error_message = "streaming module resources no longer match the applied state."
  }

  assert {
    condition     = output.module_resource_attributes["module.streaming"]["google_managed_kafka_cluster.kafka"].cluster_id == "wiki-kafka"
    error_message = "streaming Kafka cluster_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.streaming"]["google_managed_kafka_cluster.kafka"].location == "europe-west3"
    error_message = "streaming Kafka cluster region drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.streaming"]["google_managed_kafka_topic.recentchange_raw"].topic_id == "recentchange_raw"
    error_message = "streaming Kafka topic_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.streaming"]["google_service_account.producer_sa"].account_id == "wiki-producer"
    error_message = "streaming producer SA account_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.streaming"]["google_service_account.processing_sa"].account_id == "wiki-processing"
    error_message = "streaming processing SA account_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.streaming"]["kubernetes_service_account_v1.producer"].metadata[0].namespace == "wikistream"
    error_message = "streaming producer Kubernetes SA namespace drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.streaming"]["google_secret_manager_secret.kafka_bootstrap"].secret_id == "kafka_bootstrap_servers"
    error_message = "streaming kafka bootstrap secret_id drifted."
  }
}

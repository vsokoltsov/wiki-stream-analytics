resource "google_secret_manager_secret" "wiki_user_agent" {
  secret_id = "wiki_user_agent"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "wiki_user_agent_v1" {
  secret      = google_secret_manager_secret.wiki_user_agent.id
  secret_data = "wiki-stream-analytics/0.1 (https://github.com/your/repo; contact: you@domain)"
}

resource "google_secret_manager_secret" "kafka_bootstrap" {
  secret_id = "kafka_bootstrap_servers"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "kafka_bootstrap_mtls" {
  secret_id = "kafka_bootstrap_mtls"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "kafka_bootstrap_v1" {
  secret      = google_secret_manager_secret.kafka_bootstrap.id
  secret_data = local.kafka_bootstrap_plain

  depends_on = [google_managed_kafka_cluster.kafka]
}

resource "google_secret_manager_secret_version" "kafka_bootstrap_mtls_v1" {
  secret      = google_secret_manager_secret.kafka_bootstrap_mtls.id
  secret_data = local.kafka_bootstrap_mtls

  depends_on = [google_managed_kafka_cluster.kafka]
}

resource "google_secret_manager_secret" "kafka_sasl_username" {
  secret_id = "kafka_sasl_username"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "kafka_sasl_username_v1" {
  secret      = google_secret_manager_secret.kafka_sasl_username.id
  secret_data = google_service_account.producer_sa.email
}

resource "google_secret_manager_secret" "kafka_sasl_username_processing" {
  secret_id = "kafka_sasl_username_processing"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "kafka_sasl_username_processing_v1" {
  secret      = google_secret_manager_secret.kafka_sasl_username_processing.id
  secret_data = google_service_account.processing_sa.email
}


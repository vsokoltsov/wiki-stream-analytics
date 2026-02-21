locals {
  kafka_bootstrap_plain = "bootstrap.${google_managed_kafka_cluster.kafka.cluster_id}.${var.region}.managedkafka.${var.project_id}.cloud.goog:9092"
  kafka_bootstrap_mtls  = "bootstrap.${google_managed_kafka_cluster.kafka.cluster_id}.${var.region}.managedkafka.${var.project_id}.cloud.goog:9192"
}


resource "google_secret_manager_secret" "wiki_user_agent" {
  secret_id = "wiki_user_agent"
  replication {
    auto {
    }
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "wiki_user_agent_v1" {
  secret      = google_secret_manager_secret.wiki_user_agent.id
  secret_data = "wiki-stream-analytics/0.1 (https://github.com/your/repo; contact: you@domain)"

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret" "kafka_bootstrap" {
  secret_id = "kafka_bootstrap_servers"
  replication {
    auto {
    }
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

  depends_on = [
    google_managed_kafka_cluster.kafka,
    google_project_service.secretmanager
  ]
}

resource "google_secret_manager_secret_version" "kafka_bootstrap_mtls_v1" {
  secret      = google_secret_manager_secret.kafka_bootstrap_mtls.id
  secret_data = local.kafka_bootstrap_mtls
  depends_on  = [
    google_managed_kafka_cluster.kafka,
    google_project_service.secretmanager
  ]
}

resource "google_secret_manager_secret" "kafka_sasl_username" {
  secret_id = "kafka_sasl_username"
  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "kafka_sasl_username_v1" {
  secret      = google_secret_manager_secret.kafka_sasl_username.id
  secret_data = google_service_account.producer_sa.email

  depends_on = [
    google_service_account.producer_sa,
    google_project_service.secretmanager
  ]
}
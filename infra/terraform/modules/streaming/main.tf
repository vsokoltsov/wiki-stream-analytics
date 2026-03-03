locals {
  kafka_bootstrap_plain = "bootstrap.${google_managed_kafka_cluster.kafka.cluster_id}.${var.region}.managedkafka.${var.project_id}.cloud.goog:9092"
  kafka_bootstrap_mtls  = "bootstrap.${google_managed_kafka_cluster.kafka.cluster_id}.${var.region}.managedkafka.${var.project_id}.cloud.goog:9192"
}

resource "google_managed_kafka_cluster" "kafka" {
  provider   = google-beta
  cluster_id = "wiki-kafka"
  location   = var.region

  capacity_config {
    vcpu_count   = 3
    memory_bytes = 4294967296
  }

  gcp_config {
    access_config {
      network_configs {
        subnet = var.subnetwork_id
      }
    }
  }
}

resource "google_managed_kafka_topic" "recentchange_raw" {
  provider = google-beta
  cluster  = google_managed_kafka_cluster.kafka.cluster_id
  location = var.region
  topic_id = "recentchange_raw"

  partition_count    = 6
  replication_factor = 3
}

resource "google_service_account" "producer_sa" {
  account_id   = "wiki-producer"
  display_name = "Wiki Producer SA"
}

resource "google_service_account" "processing_sa" {
  account_id   = "wiki-processing"
  display_name = "Wiki Processing SA"
}

resource "kubernetes_service_account_v1" "processing" {
  metadata {
    name      = "processing-sa"
    namespace = var.app_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.processing_sa.email
    }
  }
}

resource "kubernetes_service_account_v1" "producer" {
  metadata {
    name      = "producer-sa"
    namespace = var.app_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.producer_sa.email
    }
  }
}

resource "google_project_iam_member" "producer_kafka" {
  project = var.project_id
  role    = "roles/managedkafka.client"
  member  = "serviceAccount:${google_service_account.producer_sa.email}"
}

resource "google_project_iam_member" "processing_kafka" {
  project = var.project_id
  role    = "roles/managedkafka.client"
  member  = "serviceAccount:${google_service_account.processing_sa.email}"
}

resource "google_service_account_iam_member" "producer_wi" {
  service_account_id = google_service_account.producer_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.app_namespace}/producer-sa]"
}

resource "google_service_account_iam_member" "processing_wi" {
  service_account_id = google_service_account.processing_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.app_namespace}/processing-sa]"
}

resource "google_project_iam_member" "producer_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.producer_sa.email}"
}

resource "google_project_iam_member" "processing_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.processing_sa.email}"
}

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

resource "google_secret_manager_secret" "gcs_bucket" {
  secret_id = "gcs_bucket"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gcs_bucket_v1" {
  secret      = google_secret_manager_secret.gcs_bucket.id
  secret_data = var.datalake_bucket
}

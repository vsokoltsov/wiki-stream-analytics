locals {
  kafka_bootstrap_plain = "bootstrap.${google_managed_kafka_cluster.kafka.cluster_id}.${var.region}.managedkafka.${var.project_id}.cloud.goog:9092"
  kafka_bootstrap_mtls  = "bootstrap.${google_managed_kafka_cluster.kafka.cluster_id}.${var.region}.managedkafka.${var.project_id}.cloud.goog:9192"
}


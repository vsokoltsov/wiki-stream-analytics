# NOTE: Intentionally destroyed in Mar 2026 for cost control.
# Keep definition for later re-provisioning.
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

# NOTE: Intentionally destroyed in Mar 2026 for cost control.
# Keep definition for later re-provisioning.
resource "google_managed_kafka_topic" "recentchange_raw" {
  provider = google-beta
  cluster  = google_managed_kafka_cluster.kafka.cluster_id
  location = var.region
  topic_id = "recentchange_raw"

  partition_count    = 6
  replication_factor = 3
}

# NOTE: Intentionally destroyed in Mar 2026 for cost control.
# Keep definition for later re-provisioning.
resource "google_container_cluster" "gke" {
  name     = "wiki-gke"
  location = var.region
  provider = google-beta

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_name
  subnetwork = var.subnetwork_name

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false

    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  secret_manager_config {
    enabled = true
  }

  secret_sync_config {
    enabled = true
  }

  deletion_protection = false
}

resource "google_container_cluster" "gke" {
  name     = "wiki-gke"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  node_config {
    machine_type = "e2-small"

    disk_type    = "pd-standard"   # or "pd-standard"
    disk_size_gb = 20

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  
  depends_on = [google_project_service.gke]
  deletion_protection = false
}
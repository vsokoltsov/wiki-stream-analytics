resource "google_container_node_pool" "primary" {
  name     = "primary-pool"
  cluster  = google_container_cluster.gke.name
  location = var.region

  node_config {
    machine_type = "e2-medium"

    disk_type    = "pd-standard"
    disk_size_gb = 20

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    service_account = google_service_account.gke_nodes.email
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 4
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  timeouts {
    update = "90m"
    create = "60m"
    delete = "60m"
  }

  upgrade_settings {
    max_surge       = 0
    max_unavailable = 1
  }
}


locals {
  gha_ci_sa = "serviceAccount:${var.ci_service_account_email}"
}

resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes"
  display_name = "GKE Nodes SA"
}

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

resource "google_project_iam_member" "gha_gke_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gha_gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = local.gha_ci_sa
}

resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

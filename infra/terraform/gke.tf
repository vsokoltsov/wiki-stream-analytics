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

  secret_manager_config {
    enabled = true
  }
  
  depends_on = [google_project_service.gke]
  deletion_protection = false
}

resource "google_container_node_pool" "primary" {
  name     = "primary-pool"
  cluster  = google_container_cluster.gke.name
  location = var.region

  node_count = 1

  node_config {
    machine_type = "e2-medium"

    disk_type    = "pd-standard"
    disk_size_gb = 20

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    service_account = google_service_account.gke_nodes.email
  }

  autoscaling {
    min_node_count = 3
    max_node_count = 10
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
}

# Give "cluster-admin" to whoever authenticates as gha-ci via gcloud/kubectl
# The identity string depends on how GKE maps Google identities.
# Most commonly it's: user:<EMAIL>
resource "kubernetes_cluster_role_binding_v1" "gha_cluster_admin" {
  metadata {
    name = "gha-ci-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = google_service_account.ci.email
    api_group = "rbac.authorization.k8s.io"
  }
}
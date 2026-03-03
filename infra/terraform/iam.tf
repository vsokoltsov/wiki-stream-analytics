data "google_project" "this" {
  project_id = var.project_id
}

locals {
  gha_ci_sa           = "serviceAccount:${module.ci_cd.ci_service_account_email}"
  cloudbuild_sa_email = "${data.google_project.this.number}@cloudbuild.gserviceaccount.com"

}

# Allow CI to read cluster metadata (needed for get-credentials)
resource "google_project_iam_member" "gha_gke_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = local.gha_ci_sa
}

# Needed to call container API + generate kubeconfig credentials
# (in practice, this role avoids a bunch of "permission denied" edges)
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

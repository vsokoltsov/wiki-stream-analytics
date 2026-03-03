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

data "google_storage_project_service_account" "gcs" {
  project    = var.project_id
  depends_on = [module.bootstrap]
}

resource "google_pubsub_topic_iam_member" "allow_gcs_publish" {
  topic  = google_pubsub_topic.datalake_objects.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"

  depends_on = [module.bootstrap]
}

resource "google_storage_bucket_iam_member" "processing_gcs_object_admin" {
  bucket = google_storage_bucket.datalake.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.streaming.processing_service_account_email}"
}

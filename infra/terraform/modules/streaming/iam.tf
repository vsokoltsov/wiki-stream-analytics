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


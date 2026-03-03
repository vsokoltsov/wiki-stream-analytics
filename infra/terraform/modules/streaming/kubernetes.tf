resource "kubernetes_service_account_v1" "processing" {
  metadata {
    name      = "processing-sa"
    namespace = var.app_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.processing_sa.email
    }
  }
}

resource "kubernetes_service_account_v1" "producer" {
  metadata {
    name      = "producer-sa"
    namespace = var.app_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.producer_sa.email
    }
  }
}


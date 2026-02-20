resource "google_service_account" "ci" {
  account_id   = var.ci_sa_account_id   # e.g. "gha-ci"
  display_name = "GitHub Actions CI"
}

resource "google_service_account" "cloudbuild_runner" {
  account_id   = "cloudbuild-runner"
  display_name = "Cloud Build Runner"
}

resource "google_service_account" "producer_sa" {
  account_id   = "wiki-producer"
  display_name = "Wiki Producer SA"
}

resource "kubernetes_service_account_v1" "producer" {
  depends_on = [kubernetes_namespace_v1.wikistream]

  metadata {
    name      = "producer-sa"
    namespace = kubernetes_namespace_v1.wikistream.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.producer_sa.email
    }
  }
}

resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes"
  display_name = "GKE Nodes SA"
}
resource "google_service_account" "producer_sa" {
  account_id   = "wiki-producer"
  display_name = "Wiki Producer SA"
}

resource "google_service_account" "processing_sa" {
  account_id   = "wiki-processing"
  display_name = "Wiki Processing SA"
}

resource "kubernetes_service_account_v1" "processing" {
  depends_on = [kubernetes_namespace_v1.wikistream]

  metadata {
    name      = "processing-sa"
    namespace = kubernetes_namespace_v1.wikistream.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.processing_sa.email
    }
  }
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

resource "google_service_account" "dataflow_sa" {
  account_id   = "dataflow-wikistream-sa"
  display_name = "Dataflow SA for wikistream pipeline"
}

resource "google_service_account" "dbt_sa" {
  account_id   = "dbt-wikistream-sa"
  display_name = "DBT SA for wikistream analytics"
}

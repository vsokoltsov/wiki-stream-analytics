resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes"
  display_name = "GKE Nodes SA"
}

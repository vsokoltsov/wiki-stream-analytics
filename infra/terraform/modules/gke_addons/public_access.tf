# NOTE: Intentionally destroyed in Mar 2026 for cost control.
# Keep definition for later re-provisioning.
resource "google_compute_address" "flink_ip" {
  name    = "wikistream-flink-ip"
  region  = var.region
  project = var.project_id
}

# NOTE: Intentionally destroyed in Mar 2026 for cost control.
# Keep definition for later re-provisioning.
resource "google_compute_firewall" "allow_lb" {
  name    = "allow-external-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

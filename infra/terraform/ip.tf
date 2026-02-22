resource "google_compute_address" "flink_ip" {
  name    = "wikistream-flink-ip"
  region  = var.region
  project = var.project_id
}

resource "google_compute_firewall" "allow_lb" {
  name    = "allow-external-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}
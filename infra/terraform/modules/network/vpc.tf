resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnetwork_name
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnetwork_cidr
}


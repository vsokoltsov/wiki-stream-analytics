module "network" {
  source = "./modules/network"

  region          = var.region
  network_name    = "wiki-vpc"
  subnetwork_name = "wiki-subnet"
  subnetwork_cidr = "10.10.0.0/16"
  router_name     = "wiki-router"
  cloud_nat_name  = "wiki-nat"
}

moved {
  from = google_compute_network.vpc
  to   = module.network.google_compute_network.vpc
}

moved {
  from = google_compute_subnetwork.subnet
  to   = module.network.google_compute_subnetwork.subnet
}

moved {
  from = google_compute_router.router
  to   = module.network.google_compute_router.router
}

moved {
  from = google_compute_router_nat.nat
  to   = module.network.google_compute_router_nat.nat
}

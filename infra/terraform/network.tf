module "network" {
  source = "./modules/network"

  region          = var.region
  network_name    = "wiki-vpc"
  subnetwork_name = "wiki-subnet"
  subnetwork_cidr = "10.10.0.0/16"
  router_name     = "wiki-router"
  cloud_nat_name  = "wiki-nat"
}

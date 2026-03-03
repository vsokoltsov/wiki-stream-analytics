module "gke" {
  source = "./modules/gke"

  project_id               = var.project_id
  region                   = var.region
  network_name             = module.network.network_name
  subnetwork_name          = module.network.subnetwork_name
  ci_service_account_email = module.ci_cd.ci_service_account_email

  depends_on = [module.bootstrap]
}

module "streaming" {
  source = "./modules/streaming"

  project_id    = var.project_id
  region        = var.region
  app_namespace = module.gke_addons.app_namespace
  subnetwork_id = module.network.subnetwork_id

  depends_on = [module.bootstrap]
}

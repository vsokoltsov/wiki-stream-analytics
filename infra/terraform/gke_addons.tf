module "gke_addons" {
  source = "./modules/gke_addons"

  ci_service_account_email = module.ci_cd.ci_service_account_email
  app_namespace            = var.app_namespace
  cert_manager_version     = var.cert_manager_version
  flink_operator_version   = var.flink_operator_version
  project_id               = var.project_id
  region                   = var.region

  depends_on = [module.gke]
}

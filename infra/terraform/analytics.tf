module "analytics" {
  source = "./modules/analytics"

  project_id               = var.project_id
  location                 = var.location
  region                   = var.region
  dataflow_image_version   = var.image_version
  ci_service_account_email = module.ci_cd.ci_service_account_email
  cloudbuild_runner_email  = module.ci_cd.cloudbuild_runner_service_account_email
  pubsub_subscription_name = module.data_lake.pubsub_subscription_name
  datalake_bucket_name     = module.data_lake.bucket_name

  depends_on = [module.bootstrap]
}

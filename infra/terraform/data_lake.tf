module "data_lake" {
  source = "./modules/data_lake"

  project_id                       = var.project_id
  location                         = var.location
  bucket_name                      = var.bucket_name
  name_prefix                      = var.name_prefix
  processing_service_account_email = module.streaming.processing_service_account_email

  depends_on = [module.bootstrap]
}

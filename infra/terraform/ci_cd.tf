module "ci_cd" {
  source = "./modules/ci_cd"

  project_id       = var.project_id
  region           = var.region
  github_owner     = var.github_owner
  github_repo      = var.github_repo
  wif_pool_id      = var.wif_pool_id
  wif_provider_id  = var.wif_provider_id
  ci_sa_account_id = var.ci_sa_account_id

  depends_on = [module.bootstrap]
}

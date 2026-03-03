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

moved {
  from = google_artifact_registry_repository.repo
  to   = module.ci_cd.google_artifact_registry_repository.repo
}

moved {
  from = google_storage_bucket.cloudbuild_staging
  to   = module.ci_cd.google_storage_bucket.cloudbuild_staging
}

moved {
  from = google_service_account.ci
  to   = module.ci_cd.google_service_account.ci
}

moved {
  from = google_service_account.cloudbuild_runner
  to   = module.ci_cd.google_service_account.cloudbuild_runner
}

moved {
  from = google_iam_workload_identity_pool.github
  to   = module.ci_cd.google_iam_workload_identity_pool.github
}

moved {
  from = google_iam_workload_identity_pool_provider.github
  to   = module.ci_cd.google_iam_workload_identity_pool_provider.github
}

moved {
  from = google_service_account_iam_member.wif_user
  to   = module.ci_cd.google_service_account_iam_member.wif_user
}

moved {
  from = google_project_iam_member.ar_writer
  to   = module.ci_cd.google_project_iam_member.ar_writer
}

moved {
  from = google_project_iam_member.gha_serviceusage_consumer
  to   = module.ci_cd.google_project_iam_member.gha_serviceusage_consumer
}

moved {
  from = google_project_iam_member.gha_cloudbuild_editor
  to   = module.ci_cd.google_project_iam_member.gha_cloudbuild_editor
}

moved {
  from = google_storage_bucket_iam_member.gha_staging_object_admin
  to   = module.ci_cd.google_storage_bucket_iam_member.gha_staging_object_admin
}

moved {
  from = google_storage_bucket_iam_member.gha_ci_object_admin
  to   = module.ci_cd.google_storage_bucket_iam_member.gha_ci_object_admin
}

moved {
  from = google_storage_bucket_iam_member.gha_ci_bucket_viewer
  to   = module.ci_cd.google_storage_bucket_iam_member.gha_ci_bucket_viewer
}

moved {
  from = google_project_iam_member.runner_ar_writer
  to   = module.ci_cd.google_project_iam_member.runner_ar_writer
}

moved {
  from = google_project_iam_member.runner_logs_writer
  to   = module.ci_cd.google_project_iam_member.runner_logs_writer
}

moved {
  from = google_storage_bucket_iam_member.cloudbuild_runner_object_viewer
  to   = module.ci_cd.google_storage_bucket_iam_member.cloudbuild_runner_object_viewer
}

moved {
  from = google_service_account_iam_member.gha_actas_runner
  to   = module.ci_cd.google_service_account_iam_member.gha_actas_runner
}

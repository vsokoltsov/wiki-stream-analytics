variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "ci_cd_state_matches_current_stack" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = trimspace(file("terraform.tfstate")) != "" ? file("terraform.tfstate") : file("terraform.tfstate.backup")
  }

  assert {
    condition = (
      toset(output.module_resources["module.ci_cd"]) == toset([
        "google_artifact_registry_repository.repo",
        "google_iam_workload_identity_pool.github",
        "google_iam_workload_identity_pool_provider.github",
        "google_project.this",
        "google_project_iam_member.ar_writer",
        "google_project_iam_member.gha_cloudbuild_editor",
        "google_project_iam_member.gha_serviceusage_consumer",
        "google_project_iam_member.runner_ar_writer",
        "google_project_iam_member.runner_logs_writer",
        "google_service_account.ci",
        "google_service_account.cloudbuild_runner",
        "google_service_account_iam_member.gha_actas_runner",
        "google_service_account_iam_member.wif_user",
        "google_storage_bucket.cloudbuild_staging",
        "google_storage_bucket_iam_member.cloudbuild_runner_object_viewer",
        "google_storage_bucket_iam_member.gha_ci_bucket_viewer",
        "google_storage_bucket_iam_member.gha_ci_object_admin",
        "google_storage_bucket_iam_member.gha_staging_object_admin",
      ])
    ) || (
      toset(output.module_resources["module.ci_cd"]) == toset([
        "google_artifact_registry_repository.repo",
        "google_iam_workload_identity_pool.github",
        "google_iam_workload_identity_pool_provider.github",
        "google_project.this",
        "google_project_iam_member.ar_writer",
        "google_project_iam_member.gha_cloudbuild_editor",
        "google_project_iam_member.gha_iam_security_reviewer",
        "google_project_iam_member.gha_managedkafka_viewer",
        "google_project_iam_member.gha_pubsub_viewer",
        "google_project_iam_member.gha_secretmanager_viewer",
        "google_project_iam_member.gha_service_account_viewer",
        "google_project_iam_member.gha_serviceusage_consumer",
        "google_project_iam_member.gha_storage_admin",
        "google_project_iam_member.gha_viewer",
        "google_project_iam_member.gha_workload_identity_pool_viewer",
        "google_project_iam_member.runner_ar_writer",
        "google_project_iam_member.runner_logs_writer",
        "google_service_account.ci",
        "google_service_account.cloudbuild_runner",
        "google_service_account_iam_member.gha_actas_runner",
        "google_service_account_iam_member.wif_user",
        "google_storage_bucket.cloudbuild_staging",
        "google_storage_bucket_iam_member.cloudbuild_runner_object_viewer",
        "google_storage_bucket_iam_member.gha_ci_bucket_viewer",
        "google_storage_bucket_iam_member.gha_ci_object_admin",
        "google_storage_bucket_iam_member.gha_staging_object_admin",
      ])
    )
    error_message = "ci_cd module resources no longer match either the pre-bootstrap or post-bootstrap applied state."
  }

  assert {
    condition     = output.module_resource_attributes["module.ci_cd"]["google_artifact_registry_repository.repo"].repository_id == "wiki-stream-analytics"
    error_message = "ci_cd Artifact Registry repository name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.ci_cd"]["google_artifact_registry_repository.repo"].location == "europe-west3"
    error_message = "ci_cd Artifact Registry repository should stay in europe-west3."
  }

  assert {
    condition     = output.module_resource_attributes["module.ci_cd"]["google_service_account.ci"].account_id == "gha-ci"
    error_message = "ci_cd CI service account account_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.ci_cd"]["google_service_account.cloudbuild_runner"].account_id == "cloudbuild-runner"
    error_message = "ci_cd Cloud Build runner service account account_id drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.ci_cd"]["google_storage_bucket.cloudbuild_staging"].name == "wiki-stream-analytics-cloudbuild-staging"
    error_message = "ci_cd Cloud Build staging bucket name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.ci_cd"]["google_iam_workload_identity_pool_provider.github"].attribute_condition == "assertion.repository == \"vsokoltsov/wiki-stream-analytics\""
    error_message = "ci_cd GitHub workload identity provider repository restriction drifted."
  }
}

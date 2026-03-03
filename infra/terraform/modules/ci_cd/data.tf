data "google_project" "this" {
  project_id = var.project_id
}

locals {
  gha_ci_sa           = "serviceAccount:${google_service_account.ci.email}"
  cloudbuild_sa_email = "${data.google_project.this.number}@cloudbuild.gserviceaccount.com"
}


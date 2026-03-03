resource "google_storage_bucket" "dataflow_staging" {
  name                        = "${var.project_id}-dataflow-staging"
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition { age = 7 }
    action { type = "Delete" }
  }
}

resource "google_storage_bucket" "dataflow_temp" {
  name                        = "${var.project_id}-dataflow-temp"
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition { age = 7 }
    action { type = "Delete" }
  }
}

resource "google_storage_bucket" "dataflow_templates" {
  name                        = "${var.project_id}-dataflow-templates"
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition { age = 30 }
    action { type = "Delete" }
  }
}


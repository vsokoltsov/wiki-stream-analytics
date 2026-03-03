resource "google_storage_bucket" "datalake" {
  name                        = var.bucket_name
  location                    = var.location
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "flink_state" {
  name                        = "${var.name_prefix}-flink-state"
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}


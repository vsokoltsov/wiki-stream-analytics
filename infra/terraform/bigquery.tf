resource "google_bigquery_dataset" "raw" {
  dataset_id = "wikistream_raw"
  location   = var.location
}

# 2) Table (RAW/Staging)
resource "google_bigquery_table" "events" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  table_id   = "recentchanges"

  deletion_protection = true
  require_partition_filter = true

  schema = jsonencode([
    { name = "event_ts",      type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "wiki",          type = "STRING",    mode = "NULLABLE" },
    { name = "type",          type = "STRING",    mode = "NULLABLE" },
    { name = "user_name",     type = "STRING",    mode = "NULLABLE" },
    { name = "bot",           type = "BOOL",      mode = "NULLABLE" },
    { name = "title",         type = "STRING",    mode = "NULLABLE" },
    { name = "namespace_id",  type = "INT64",     mode = "NULLABLE" }
  ])

  time_partitioning {
    type  = "DAY"
    field = "event_ts"
  }

  clustering = ["wiki", "namespace_id"]

  # чтобы Terraform не “пересоздавал” таблицу при мелких изменениях схемы:
  lifecycle {
    ignore_changes = [schema]
  }
}
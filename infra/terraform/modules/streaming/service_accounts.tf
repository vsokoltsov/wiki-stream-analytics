resource "google_service_account" "producer_sa" {
  account_id   = "wiki-producer"
  display_name = "Wiki Producer SA"
}

resource "google_service_account" "processing_sa" {
  account_id   = "wiki-processing"
  display_name = "Wiki Processing SA"
}


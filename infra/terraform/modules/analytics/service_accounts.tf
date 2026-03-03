resource "google_service_account" "dataflow_sa" {
  account_id   = "dataflow-wikistream-sa"
  display_name = "Dataflow SA for wikistream pipeline"
}

resource "google_service_account" "dbt_sa" {
  account_id   = "dbt-wikistream-sa"
  display_name = "DBT SA for wikistream analytics"
}


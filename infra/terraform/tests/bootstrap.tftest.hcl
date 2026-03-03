variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "bootstrap_state_matches_current_stack" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = file("terraform.tfstate")
  }

  assert {
    condition = toset(output.module_resources["module.bootstrap"]) == toset([
      "google_project_service.artifactregistry",
      "google_project_service.bigquery",
      "google_project_service.cloudbuild",
      "google_project_service.cloudresourcemanager",
      "google_project_service.compute",
      "google_project_service.dataflow",
      "google_project_service.gke",
      "google_project_service.iam",
      "google_project_service.managedkafka",
      "google_project_service.pubsub",
      "google_project_service.secretmanager",
      "google_project_service.serviceusage",
      "google_project_service.storage",
    ])
    error_message = "Bootstrap module resources no longer match the applied state."
  }

  assert {
    condition     = output.module_resource_attributes["module.bootstrap"]["google_project_service.gke"].service == "container.googleapis.com"
    error_message = "bootstrap should enable the GKE API."
  }

  assert {
    condition     = output.module_resource_attributes["module.bootstrap"]["google_project_service.managedkafka"].service == "managedkafka.googleapis.com"
    error_message = "bootstrap should enable the Managed Kafka API."
  }

  assert {
    condition     = output.module_resource_attributes["module.bootstrap"]["google_project_service.secretmanager"].service == "secretmanager.googleapis.com"
    error_message = "bootstrap should enable the Secret Manager API."
  }
}

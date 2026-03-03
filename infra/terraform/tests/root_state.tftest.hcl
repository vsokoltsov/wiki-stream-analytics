variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "root_state_matches_current_stack" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = file("terraform.tfstate")
  }

  assert {
    condition = toset(output.root_resources) == toset([
      "google_client_config.default",
    ])
    error_message = "Root state resources no longer match the applied state."
  }

  assert {
    condition = toset(keys(output.module_resources)) == toset([
      "module.analytics",
      "module.bootstrap",
      "module.ci_cd",
      "module.data_lake",
      "module.gke",
      "module.gke_addons",
      "module.network",
      "module.streaming",
    ])
    error_message = "Root module set drifted from the current stack composition."
  }
}

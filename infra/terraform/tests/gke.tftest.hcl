variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "gke_state_matches_current_stack" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = file("terraform.tfstate")
  }

  assert {
    condition = toset(output.module_resources["module.gke"]) == toset([
      "google_container_cluster.gke",
      "google_container_node_pool.primary",
      "google_project_iam_member.gha_gke_developer",
      "google_project_iam_member.gha_gke_viewer",
      "google_project_iam_member.gke_nodes_ar_reader",
      "google_project_iam_member.gke_nodes_log_writer",
      "google_project_iam_member.gke_nodes_metric_writer",
      "google_service_account.gke_nodes",
    ])
    error_message = "gke module resources no longer match the applied state."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].name == "wiki-gke"
    error_message = "gke cluster name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].location == "europe-west3"
    error_message = "gke cluster region drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].private_cluster_config[0].enable_private_nodes == true
    error_message = "gke cluster should keep private nodes enabled."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].workload_identity_config[0].workload_pool == "wiki-stream-analytics.svc.id.goog"
    error_message = "gke workload identity pool drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke"]["google_container_node_pool.primary"].name == "primary-pool"
    error_message = "gke node pool name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke"]["google_container_node_pool.primary"].node_config[0].machine_type == "e2-medium"
    error_message = "gke node pool machine type drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke"]["google_service_account.gke_nodes"].account_id == "gke-nodes"
    error_message = "gke nodes service account account_id drifted."
  }
}

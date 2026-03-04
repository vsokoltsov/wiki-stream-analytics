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
    state_json = trimspace(file("terraform.tfstate")) != "" ? file("terraform.tfstate") : file("terraform.tfstate.backup")
  }

  assert {
    # Allow both states:
    # - active: cluster + node pool exist
    # - destroyed: costly GKE compute resources intentionally removed
    condition = (
      try(toset(output.module_resources["module.gke"]), toset([])) == toset([
        "google_container_cluster.gke",
        "google_container_node_pool.primary",
        "google_project_iam_member.gha_gke_developer",
        "google_project_iam_member.gha_gke_viewer",
        "google_project_iam_member.gke_nodes_ar_reader",
        "google_project_iam_member.gke_nodes_log_writer",
        "google_project_iam_member.gke_nodes_metric_writer",
        "google_service_account.gke_nodes",
      ])
      ) || (
      try(toset(output.module_resources["module.gke"]), toset([])) == toset([
        "google_project_iam_member.gha_gke_developer",
        "google_project_iam_member.gha_gke_viewer",
        "google_project_iam_member.gke_nodes_ar_reader",
        "google_project_iam_member.gke_nodes_log_writer",
        "google_project_iam_member.gke_nodes_metric_writer",
        "google_service_account.gke_nodes",
      ])
    )
    error_message = "gke module resources no longer match either the active or intentionally destroyed state."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].name, "destroyed") == "wiki-gke"
      ) || (
      try(output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].name, "destroyed") == "destroyed"
    )
    error_message = "gke cluster name drifted when cluster exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].location, "destroyed") == "europe-west3"
      ) || (
      try(output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].location, "destroyed") == "destroyed"
    )
    error_message = "gke cluster region drifted when cluster exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].private_cluster_config[0].enable_private_nodes, true) == true
      ) || (
      try(output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].name, "destroyed") == "destroyed"
    )
    error_message = "gke cluster should keep private nodes enabled when cluster exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].workload_identity_config[0].workload_pool, "destroyed") == "wiki-stream-analytics.svc.id.goog"
      ) || (
      try(output.module_resource_attributes["module.gke"]["google_container_cluster.gke"].name, "destroyed") == "destroyed"
    )
    error_message = "gke workload identity pool drifted when cluster exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke"]["google_container_node_pool.primary"].name, "destroyed") == "primary-pool"
      ) || (
      try(output.module_resource_attributes["module.gke"]["google_container_node_pool.primary"].name, "destroyed") == "destroyed"
    )
    error_message = "gke node pool name drifted when node pool exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke"]["google_container_node_pool.primary"].node_config[0].machine_type, "destroyed") == "e2-medium"
      ) || (
      try(output.module_resource_attributes["module.gke"]["google_container_node_pool.primary"].name, "destroyed") == "destroyed"
    )
    error_message = "gke node pool machine type drifted when node pool exists."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke"]["google_service_account.gke_nodes"].account_id == "gke-nodes"
    error_message = "gke nodes service account account_id drifted."
  }
}

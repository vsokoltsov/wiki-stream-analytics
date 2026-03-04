variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "gke_addons_state_matches_current_stack" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = trimspace(file("terraform.tfstate")) != "" ? file("terraform.tfstate") : file("terraform.tfstate.backup")
  }

  assert {
    # Allow both states:
    # - active: addons are deployed
    # - destroyed: addons intentionally removed to cut costs
    condition = (
      try(toset(output.module_resources["module.gke_addons"]), toset([])) == toset([
        "google_compute_address.flink_ip",
        "google_compute_firewall.allow_lb",
        "helm_release.cert_manager",
        "helm_release.flink_operator",
        "http.gcp_provider_yaml",
        "kubernetes_cluster_role_binding_v1.gha_cluster_admin",
        "kubernetes_namespace_v1.cert_manager",
        "kubernetes_namespace_v1.flink_operator",
        "kubernetes_namespace_v1.wikistream",
      ])
      ) || (
      try(toset(output.module_resources["module.gke_addons"]), toset([])) == toset([
        "http.gcp_provider_yaml",
      ])
      ) || (
      try(toset(output.module_resources["module.gke_addons"]), toset([])) == toset([])
    )
    error_message = "gke_addons module resources no longer match either the active or intentionally destroyed state."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke_addons"]["google_compute_address.flink_ip"].name, "destroyed") == "wikistream-flink-ip"
      ) || (
      try(output.module_resource_attributes["module.gke_addons"]["google_compute_address.flink_ip"].name, "destroyed") == "destroyed"
    )
    error_message = "gke_addons Flink public IP resource name drifted when resource exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke_addons"]["google_compute_address.flink_ip"].region, "destroyed") == "europe-west3"
      ) || (
      try(output.module_resource_attributes["module.gke_addons"]["google_compute_address.flink_ip"].region, "destroyed") == "destroyed"
    )
    error_message = "gke_addons Flink public IP region drifted when resource exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke_addons"]["google_compute_firewall.allow_lb"].name, "destroyed") == "allow-external-http"
      ) || (
      try(output.module_resource_attributes["module.gke_addons"]["google_compute_firewall.allow_lb"].name, "destroyed") == "destroyed"
    )
    error_message = "gke_addons load balancer firewall name drifted when resource exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke_addons"]["kubernetes_namespace_v1.wikistream"].metadata[0].name, "destroyed") == "wikistream"
      ) || (
      try(output.module_resource_attributes["module.gke_addons"]["kubernetes_namespace_v1.wikistream"].metadata[0].name, "destroyed") == "destroyed"
    )
    error_message = "gke_addons app namespace name drifted when namespace exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke_addons"]["helm_release.cert_manager"].version, "destroyed") == "v1.18.2"
      ) || (
      try(output.module_resource_attributes["module.gke_addons"]["helm_release.cert_manager"].version, "destroyed") == "destroyed"
    )
    error_message = "gke_addons cert-manager version drifted when release exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke_addons"]["helm_release.flink_operator"].version, "destroyed") == "1.14.0"
      ) || (
      try(output.module_resource_attributes["module.gke_addons"]["helm_release.flink_operator"].version, "destroyed") == "destroyed"
    )
    error_message = "gke_addons Flink operator version drifted when release exists."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.gke_addons"]["helm_release.flink_operator"].set[0].value, "destroyed") == "{wikistream}"
      ) || (
      try(output.module_resource_attributes["module.gke_addons"]["helm_release.flink_operator"].set[0].value, "destroyed") == "destroyed"
    )
    error_message = "gke_addons Flink operator watched namespace drifted when release exists."
  }
}

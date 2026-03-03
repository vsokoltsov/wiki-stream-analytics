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
    state_json = file("terraform.tfstate")
  }

  assert {
    condition = toset(output.module_resources["module.gke_addons"]) == toset([
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
    error_message = "gke_addons module resources no longer match the applied state."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke_addons"]["google_compute_address.flink_ip"].name == "wikistream-flink-ip"
    error_message = "gke_addons Flink public IP resource name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke_addons"]["google_compute_address.flink_ip"].region == "europe-west3"
    error_message = "gke_addons Flink public IP region drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke_addons"]["google_compute_firewall.allow_lb"].name == "allow-external-http"
    error_message = "gke_addons load balancer firewall name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke_addons"]["kubernetes_namespace_v1.wikistream"].metadata[0].name == "wikistream"
    error_message = "gke_addons app namespace name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke_addons"]["helm_release.cert_manager"].version == "v1.18.2"
    error_message = "gke_addons cert-manager version drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke_addons"]["helm_release.flink_operator"].version == "1.14.0"
    error_message = "gke_addons Flink operator version drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.gke_addons"]["helm_release.flink_operator"].set[0].value == "{wikistream}"
    error_message = "gke_addons Flink operator watched namespace drifted."
  }
}

variables {
  project_id   = "wiki-stream-analytics"
  region       = "europe-west3"
  zone         = "europe-west3-a"
  github_owner = "vsokoltsov"
  github_repo  = "wiki-stream-analytics"
  bucket_name  = "wikistream-datalake"
}

run "network_state_matches_current_stack" {
  command = plan

  module {
    source = "./tests/state_contract"
  }

  variables {
    state_json = trimspace(file("terraform.tfstate")) != "" ? file("terraform.tfstate") : file("terraform.tfstate.backup")
  }

  assert {
    # Allow both states:
    # - active: router NAT exists
    # - destroyed: NAT intentionally removed to reduce baseline cost
    condition = (
      try(toset(output.module_resources["module.network"]), toset([])) == toset([
        "google_compute_network.vpc",
        "google_compute_router.router",
        "google_compute_router_nat.nat",
        "google_compute_subnetwork.subnet",
      ])
      ) || (
      try(toset(output.module_resources["module.network"]), toset([])) == toset([
        "google_compute_network.vpc",
        "google_compute_router.router",
        "google_compute_subnetwork.subnet",
      ])
    )
    error_message = "network module resources no longer match either the active or intentionally destroyed state."
  }

  assert {
    condition     = output.module_resource_attributes["module.network"]["google_compute_network.vpc"].name == "wiki-vpc"
    error_message = "network VPC name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.network"]["google_compute_subnetwork.subnet"].name == "wiki-subnet"
    error_message = "network subnet name drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.network"]["google_compute_subnetwork.subnet"].ip_cidr_range == "10.10.0.0/16"
    error_message = "network subnet CIDR drifted."
  }

  assert {
    condition     = output.module_resource_attributes["module.network"]["google_compute_router.router"].name == "wiki-router"
    error_message = "network router name drifted."
  }

  assert {
    condition = (
      try(output.module_resource_attributes["module.network"]["google_compute_router_nat.nat"].name, "destroyed") == "wiki-nat"
      ) || (
      try(output.module_resource_attributes["module.network"]["google_compute_router_nat.nat"].name, "destroyed") == "destroyed"
    )
    error_message = "network Cloud NAT name drifted when NAT exists."
  }
}

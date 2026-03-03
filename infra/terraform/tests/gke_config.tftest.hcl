run "gke_config_contract" {
  command = plan

  module {
    source = "./tests/config_contract"
  }

  variables {
    files = {
      main      = file("modules/gke/main.tf")
      variables = file("modules/gke/variables.tf")
      outputs   = file("modules/gke/outputs.tf")
      providers = file("providers.tf")
    }
  }

  assert {
    condition     = length(regexall("name\\s*=\\s*\"wiki-gke\"", output.files.main)) > 0
    error_message = "gke module should define the wiki-gke cluster."
  }

  assert {
    condition     = length(regexall("enable_private_nodes\\s*=\\s*true", output.files.main)) > 0
    error_message = "gke module should keep private nodes enabled."
  }

  assert {
    condition     = length(regexall("workload_pool\\s*=\\s*\"\\$\\{var\\.project_id\\}\\.svc\\.id\\.goog\"", output.files.main)) > 0
    error_message = "gke module should derive workload identity pool from project_id."
  }

  assert {
    condition     = length(regexall("machine_type\\s*=\\s*\"e2-medium\"", output.files.main)) > 0
    error_message = "gke node pool machine type drifted."
  }

  assert {
    condition     = length(regexall("output\\s+\"cluster_endpoint\"", output.files.outputs)) > 0
    error_message = "gke module should export cluster_endpoint."
  }

  assert {
    condition     = length(regexall("host\\s*=\\s*\"https://\\$\\{module\\.gke\\.cluster_endpoint\\}\"", output.files.providers)) > 0
    error_message = "root providers should use module.gke cluster outputs."
  }
}

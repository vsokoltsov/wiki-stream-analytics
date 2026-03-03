run "bootstrap_config_contract" {
  command = plan

  module {
    source = "./tests/config_contract"
  }

  variables {
    files = {
      main      = file("modules/bootstrap/main.tf")
      variables = file("modules/bootstrap/variables.tf")
      root      = file("bootstrap.tf")
    }
  }

  assert {
    condition     = length(regexall("resource\\s+\"google_project_service\"\\s+\"gke\"", output.files.main)) > 0
    error_message = "bootstrap module should enable the GKE API."
  }

  assert {
    condition     = length(regexall("service\\s*=\\s*\"managedkafka.googleapis.com\"", output.files.main)) > 0
    error_message = "bootstrap module should enable the Managed Kafka API."
  }

  assert {
    condition     = length(regexall("variable\\s+\"project_id\"", output.files.variables)) > 0
    error_message = "bootstrap module should declare project_id."
  }

  assert {
    condition     = length(regexall("module\\s+\"bootstrap\"", output.files.root)) > 0
    error_message = "root should instantiate the bootstrap module."
  }
}

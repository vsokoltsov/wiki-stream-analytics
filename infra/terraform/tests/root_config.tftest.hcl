run "root_config_contract" {
  command = plan

  module {
    source = "./tests/config_contract"
  }

  variables {
    files = {
      providers = file("providers.tf")
      variables = file("variables.tf")
      outputs   = file("outputs.tf")
    }
  }

  assert {
    condition     = length(regexall("provider\\s+\"google\"", output.files.providers)) > 0
    error_message = "root should declare the google provider."
  }

  assert {
    condition     = length(regexall("provider\\s+\"kubernetes\"", output.files.providers)) > 0
    error_message = "root should declare the kubernetes provider."
  }

  assert {
    condition     = length(regexall("variable\\s+\"project_id\"", output.files.variables)) > 0
    error_message = "root should declare project_id."
  }

  assert {
    condition     = length(regexall("variable\\s+\"bucket_name\"", output.files.variables)) > 0
    error_message = "root should declare bucket_name."
  }

  assert {
    condition     = length(regexall("output\\s+\"flink_public_ip\"", output.files.outputs)) > 0
    error_message = "root should export flink_public_ip."
  }

  assert {
    condition     = length(regexall("value\\s*=\\s*module\\.gke_addons\\.flink_public_ip", output.files.outputs)) > 0
    error_message = "root flink_public_ip output should come from gke_addons."
  }
}

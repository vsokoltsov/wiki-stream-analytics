run "ci_cd_config_contract" {
  command = plan

  module {
    source = "./tests/config_contract"
  }

  variables {
    files = {
      main      = file("modules/ci_cd/main.tf")
      variables = file("modules/ci_cd/variables.tf")
      outputs   = file("modules/ci_cd/outputs.tf")
      root      = file("ci_cd.tf")
    }
  }

  assert {
    condition     = length(regexall("repository_id\\s*=\\s*\"wiki-stream-analytics\"", output.files.main)) > 0
    error_message = "ci_cd module should define the wiki-stream-analytics repository."
  }

  assert {
    condition     = length(regexall("account_id\\s*=\\s*var\\.ci_sa_account_id", output.files.main)) > 0
    error_message = "ci_cd module should wire the CI service account from a variable."
  }

  assert {
    condition     = length(regexall("attribute_condition\\s*=\\s*\"assertion\\.repository == \\\\\"\\$\\{var\\.github_owner\\}/\\$\\{var\\.github_repo\\}\\\\\"\"", output.files.main)) > 0
    error_message = "ci_cd module should scope Workload Identity to the configured GitHub repo."
  }

  assert {
    condition     = length(regexall("output\\s+\"ci_service_account_email\"", output.files.outputs)) > 0
    error_message = "ci_cd module should export ci_service_account_email."
  }

  assert {
    condition     = length(regexall("module\\s+\"ci_cd\"", output.files.root)) > 0
    error_message = "root should instantiate the ci_cd module."
  }
}

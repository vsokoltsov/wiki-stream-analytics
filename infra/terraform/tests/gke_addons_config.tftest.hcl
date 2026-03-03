run "gke_addons_config_contract" {
  command = plan

  module {
    source = "./tests/config_contract"
  }

  variables {
    files = {
      main      = file("modules/gke_addons/main.tf")
      variables = file("modules/gke_addons/variables.tf")
      outputs   = file("modules/gke_addons/outputs.tf")
      versions  = file("modules/gke_addons/versions.tf")
      root      = file("gke_addons.tf")
    }
  }

  assert {
    condition     = length(regexall("resource\\s+\"kubernetes_namespace_v1\"\\s+\"wikistream\"", output.files.main)) > 0
    error_message = "gke_addons should define the wikistream namespace."
  }

  assert {
    condition     = length(regexall("version\\s*=\\s*var\\.cert_manager_version", output.files.main)) > 0
    error_message = "gke_addons should wire cert-manager version from a variable."
  }

  assert {
    condition     = length(regexall("value\\s*=\\s*\"\\{\\$\\{var\\.app_namespace\\}\\}\"", output.files.main)) > 0
    error_message = "gke_addons should configure the Flink operator to watch app_namespace."
  }

  assert {
    condition     = length(regexall("name\\s*=\\s*\"wikistream-flink-ip\"", output.files.main)) > 0
    error_message = "gke_addons should define the Flink public IP resource."
  }

  assert {
    condition     = length(regexall("source\\s*=\\s*\"gavinbunney/kubectl\"", output.files.versions)) > 0
    error_message = "gke_addons should pin the kubectl provider source."
  }

  assert {
    condition     = length(regexall("output\\s+\"app_namespace\"", output.files.outputs)) > 0
    error_message = "gke_addons should export app_namespace."
  }
}

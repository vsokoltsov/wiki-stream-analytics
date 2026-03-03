run "streaming_config_contract" {
  command = plan

  module {
    source = "./tests/config_contract"
  }

  variables {
    files = {
      main      = file("modules/streaming/main.tf")
      variables = file("modules/streaming/variables.tf")
      outputs   = file("modules/streaming/outputs.tf")
      root      = file("streaming.tf")
    }
  }

  assert {
    condition     = length(regexall("cluster_id\\s*=\\s*\"wiki-kafka\"", output.files.main)) > 0
    error_message = "streaming module should define the wiki-kafka cluster."
  }

  assert {
    condition     = length(regexall("topic_id\\s*=\\s*\"recentchange_raw\"", output.files.main)) > 0
    error_message = "streaming module should define the recentchange_raw topic."
  }

  assert {
    condition     = length(regexall("namespace\\s*=\\s*var\\.app_namespace", output.files.main)) > 0
    error_message = "streaming Kubernetes service accounts should use the app_namespace variable."
  }

  assert {
    condition     = length(regexall("secret_id\\s*=\\s*\"kafka_bootstrap_servers\"", output.files.main)) > 0
    error_message = "streaming module should define the kafka bootstrap secret."
  }

  assert {
    condition     = length(regexall("variable\\s+\"subnetwork_id\"", output.files.variables)) > 0
    error_message = "streaming module should declare subnetwork_id."
  }

  assert {
    condition     = length(regexall("output\\s+\"kafka_cluster_name\"", output.files.outputs)) > 0
    error_message = "streaming module should export kafka_cluster_name."
  }

  assert {
    condition     = length(regexall("app_namespace\\s*=\\s*module\\.gke_addons\\.app_namespace", output.files.root)) > 0
    error_message = "root should wire streaming app_namespace from gke_addons."
  }
}

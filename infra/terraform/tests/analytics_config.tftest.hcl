run "analytics_config_contract" {
  command = plan

  module {
    source = "./tests/config_contract"
  }

  variables {
    files = {
      module    = join("\n", [for f in sort(tolist(fileset("modules/analytics", "*.tf"))) : file("modules/analytics/${f}")])
      variables = file("modules/analytics/variables.tf")
      outputs   = file("modules/analytics/outputs.tf")
      root      = file("analytics.tf")
    }
  }

  assert {
    condition     = length(regexall("dataset_id\\s*=\\s*\"wikistream_raw\"", output.files.module)) > 0
    error_message = "analytics module should define wikistream_raw."
  }

  assert {
    condition     = length(regexall("table_id\\s*=\\s*\"recentchanges\"", output.files.module)) > 0
    error_message = "analytics module should define the recentchanges table."
  }

  assert {
    condition     = length(regexall("require_partition_filter\\s*=\\s*true", output.files.module)) > 0
    error_message = "analytics module should require partition filters on the events table."
  }

  assert {
    condition     = length(regexall("account_id\\s*=\\s*\"dataflow-wikistream-sa\"", output.files.module)) > 0
    error_message = "analytics module should define the Dataflow service account."
  }

  assert {
    condition     = length(regexall("variable\\s+\"pubsub_subscription_name\"", output.files.variables)) > 0
    error_message = "analytics module should declare pubsub_subscription_name."
  }

  assert {
    condition     = length(regexall("output\\s+\"bq_destination_table_for_jobs\"", output.files.outputs)) > 0
    error_message = "analytics module should export bq_destination_table_for_jobs."
  }

  assert {
    condition     = length(regexall("module\\s+\"analytics\"", output.files.root)) > 0
    error_message = "root should instantiate the analytics module."
  }
}

run "data_lake_config_contract" {
  command = plan

  module {
    source = "./tests/config_contract"
  }

  variables {
    files = {
      module    = join("\n", [for f in sort(tolist(fileset("modules/data_lake", "*.tf"))) : file("modules/data_lake/${f}")])
      variables = file("modules/data_lake/variables.tf")
      outputs   = file("modules/data_lake/outputs.tf")
      root      = file("data_lake.tf")
    }
  }

  assert {
    condition     = length(regexall("resource\\s+\"google_storage_bucket\"\\s+\"datalake\"", output.files.module)) > 0
    error_message = "data_lake module should define the datalake bucket."
  }

  assert {
    condition     = length(regexall("resource\\s+\"google_storage_bucket\"\\s+\"flink_state\"", output.files.module)) > 0
    error_message = "data_lake module should define the Flink state bucket."
  }

  assert {
    condition     = length(regexall("name\\s*=\\s*\"\\$\\{var\\.name_prefix\\}-datalake-objects\"", output.files.module)) > 0
    error_message = "data_lake module should derive the Pub/Sub topic name from name_prefix."
  }

  assert {
    condition     = length(regexall("ack_deadline_seconds\\s*=\\s*30", output.files.module)) > 0
    error_message = "data_lake module should set the subscription ack deadline to 30 seconds."
  }

  assert {
    condition     = length(regexall("secret_id\\s*=\\s*\"gcs_bucket\"", output.files.module)) > 0
    error_message = "data_lake module should define the gcs_bucket secret."
  }

  assert {
    condition     = length(regexall("secret_id\\s*=\\s*\"flink_state_bucket\"", output.files.module)) > 0
    error_message = "data_lake module should define the flink_state_bucket secret."
  }

  assert {
    condition     = length(regexall("variable\\s+\"processing_service_account_email\"", output.files.variables)) > 0
    error_message = "data_lake module should declare processing_service_account_email."
  }

  assert {
    condition     = length(regexall("output\\s+\"pubsub_subscription_name\"", output.files.outputs)) > 0
    error_message = "data_lake module should export pubsub_subscription_name."
  }

  assert {
    condition     = length(regexall("output\\s+\"flink_state_bucket_name\"", output.files.outputs)) > 0
    error_message = "data_lake module should export flink_state_bucket_name."
  }

  assert {
    condition     = length(regexall("module\\s+\"data_lake\"", output.files.root)) > 0
    error_message = "root should instantiate the data_lake module."
  }
}

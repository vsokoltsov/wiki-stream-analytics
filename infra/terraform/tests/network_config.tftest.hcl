run "network_config_contract" {
  command = plan

  module {
    source = "./tests/config_contract"
  }

  variables {
    files = {
      main      = file("modules/network/main.tf")
      variables = file("modules/network/variables.tf")
      outputs   = file("modules/network/outputs.tf")
      root      = file("network.tf")
    }
  }

  assert {
    condition     = length(regexall("auto_create_subnetworks\\s*=\\s*false", output.files.main)) > 0
    error_message = "network module should disable auto-created subnetworks."
  }

  assert {
    condition     = length(regexall("ip_cidr_range\\s*=\\s*var\\.subnetwork_cidr", output.files.main)) > 0
    error_message = "network module should wire subnetwork_cidr into the subnet."
  }

  assert {
    condition     = length(regexall("name\\s*=\\s*var\\.cloud_nat_name", output.files.main)) > 0
    error_message = "network module should wire cloud_nat_name into the NAT resource."
  }

  assert {
    condition     = length(regexall("output\\s+\"subnetwork_id\"", output.files.outputs)) > 0
    error_message = "network module should export subnetwork_id."
  }

  assert {
    condition     = length(regexall("network_name\\s*=\\s*\"wiki-vpc\"", output.files.root)) > 0
    error_message = "root should wire the expected VPC name into the network module."
  }
}

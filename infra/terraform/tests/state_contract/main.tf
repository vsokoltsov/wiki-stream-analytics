variable "state_json" {
  type = string
}

locals {
  state     = jsondecode(var.state_json)
  resources = local.state.resources

  module_names = sort(distinct([
    for resource in local.resources : resource.module
    if try(resource.module, null) != null
  ]))

  module_resources = {
    for module_name in local.module_names :
    module_name => sort([
      for resource in local.resources :
      "${resource.type}.${resource.name}"
      if try(resource.module, null) == module_name
    ])
  }

  module_resource_attributes = {
    for module_name in local.module_names :
    module_name => {
      for resource in local.resources :
      "${resource.type}.${resource.name}" => resource.instances[0].attributes
      if try(resource.module, null) == module_name
    }
  }

  root_resources = sort([
    for resource in local.resources :
    "${resource.type}.${resource.name}"
    if try(resource.module, null) == null
  ])

  outputs = {
    for key, output in local.state.outputs :
    key => output.value
  }
}

output "module_resources" {
  value = local.module_resources
}

output "root_resources" {
  value = local.root_resources
}

output "outputs" {
  value = local.outputs
}

output "module_resource_attributes" {
  value = local.module_resource_attributes
}

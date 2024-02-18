# tflint-ignore-file: terraform_standard_module_structure, terraform_variable_separate, terraform_output_separate, azurerm_resource_tag

# there is no azurem data resource for locks, so we use the azapi provider
# to read the lock resources
# ref. https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource

terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">=1.12.0"
    }
  }
}

provider "azapi" {}

variable "management_lock_ids" {
  description = "A list of all the IDs of the managemnet locks"
  type        = list(string)
}

data "azapi_resource_id" "this" {
  for_each = toset(var.management_lock_ids)

  resource_id = each.value
  # https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/locks
  type = "Microsoft.Authorization/locks@2020-05-01"
}

locals {
  locks = { for lock in data.azapi_resource_id.this :
    lock.parts.locks => { # same as lock.name
      id                  = lock.id
      name                = lock.name
      parent_id           = lock.parent_id
      namespace           = lock.provider_namespace
      resource_group_name = lock.resource_group_name
      subscription_id     = lock.subscription_id
    }
  }
}

data "azapi_resource" "this" {
  for_each = local.locks

  resource_id = each.value.id
  # https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/locks
  type = "Microsoft.Authorization/locks@2020-05-01"

  response_export_values = ["*"]
}

output "map_of_locks" {
  description = <<-DESC
    map_of_locks = map(object({
      id                  = string # /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-automated-testing-0000/providers/Microsoft.Authorization/locks/lock-name-of-other-resource
      level               = string # ReadOnly
      name                = string # lock-name-of-other-resource
      namespace           = string # Microsoft.Authorization
      notes               = string # ApplicationName: my-app-name
      #                            # CreatedBy: https://github.com/my-org/my-tf-project
      #                            # Description: This is a read-only lock for the resource
      parent_id           = string # /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-automated-testing-0000
      resource_group_name = string # rg-automated-testing-0000
      subscription_id     = string # 00000000-0000-0000-0000-000000000000
    }))
  DESC
  value = { for k, v in local.locks :
    k => merge(v, {
      level = jsondecode(data.azapi_resource.this[k].output).properties.level
      notes = jsondecode(data.azapi_resource.this[k].output).properties.notes
    })
  }
}

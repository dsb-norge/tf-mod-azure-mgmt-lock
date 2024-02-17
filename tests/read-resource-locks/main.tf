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
    lock.parts.locks => {
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
  value = { for k, v in local.locks :
    k => merge(v, {
      level = jsondecode(data.azapi_resource.this[k].output).properties.level
      notes = jsondecode(data.azapi_resource.this[k].output).properties.notes
    })
  }
}

# 02-full

Example of specifying multiple locks with different configuration.

Lock confiuration `second_lock` and `third_lock` is using all available inputs.

<!-- BEGIN_TF_DOCS -->
## main.tf

```hcl
# tflint-ignore-file: azurerm_resource_tag

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = var.resource_group_name
}

resource "azurerm_dns_zone" "this" {
  name                = "mydomain.com"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_dns_a_record" "this" {
  name                = "test"
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 300
  zone_name           = azurerm_dns_zone.this.name
  records             = ["10.0.180.17"]
}

module "lock_multiple_resources" {
  source = "../../" # root of repo

  protected_resources = {
    first_lock = {
      # this is a can-not-delete lock for the resource group
      id   = azurerm_resource_group.this.id
      name = azurerm_resource_group.this.name
    }
    second_lock = {
      description = "This is a can-not-delete lock for the DNS zone"
      id          = azurerm_dns_zone.this.id
      lock_level  = "CanNotDelete"
      name        = azurerm_dns_zone.this.name
    }
    third_lock = {
      description = "This is a read-only lock for the DNS A record"
      id          = azurerm_dns_a_record.this.id
      lock_level  = "ReadOnly"
      name        = azurerm_dns_a_record.this.name
    }
  }
  app_name   = "my-app-name"
  created_by = "https://github.com/my-org/my-tf-project"
}
```

## variables.tf

```hcl
variable "location" {
  description = "The location/region where the example resource group will be created."
  type        = string
  default     = "norwayeast"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "example-resources"
}
```

## outputs.tf

```hcl
output "management_lock_ids" {
  description = "this module produces a single output: the ids of the the management locks created"
  value       = module.lock_multiple_resources.management_lock_ids
}
```
<!-- END_TF_DOCS -->
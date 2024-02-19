# 01-minimal

Example of using the module with the minimal inputs required.

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

module "prevent_resource_group_from_deletion" {
  source = "../../" # root of repo

  protected_resources = {
    lock_1 = {
      # this is a can-not-delete lock for the resource group
      id   = azurerm_resource_group.this.id
      name = azurerm_resource_group.this.name
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
  value       = module.prevent_resource_group_from_deletion.management_lock_ids
}
```
<!-- END_TF_DOCS -->
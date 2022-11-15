# tf-mod-azure-mgmt-lock

Terraform module for adding [management locks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) to resources.

## required arguments

`scope` - the id (URN) wherefore to create the lock. This can be a subscription, resource group or resource.

`name` - name of the lock. Must be unique scope-wide, will be prefixed by `lock-`.


## optional arguments

`lock_level` - [lock level](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock#lock_level), defaults to `CanNotDelete`.
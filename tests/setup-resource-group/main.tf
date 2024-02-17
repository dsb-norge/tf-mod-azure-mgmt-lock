variable "location" {
  description = "The location/region where the example resource group will be created."
  type        = string
  default     = "norwayeast"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">=0.4.0"

  suffix = ["automated-testing"]
}

resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = var.location
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.this.id
}

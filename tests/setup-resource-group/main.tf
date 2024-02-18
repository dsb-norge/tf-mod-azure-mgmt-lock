# tflint-ignore-file: terraform_standard_module_structure, terraform_variable_separate, terraform_output_separate, azurerm_resource_tag

variable "location" {
  description = "The location/region where the example resource group will be created."
  type        = string
  default     = "norwayeast"
}

variable "naming_suffix" {
  description = "The suffix to append to the names of the resources"
  type        = list(string)
  default     = ["automated-testing"]
}

# we need a random name to avoid collition with other tests
module "names" {
  source = "../generate-names"

  naming_suffix = var.naming_suffix
}

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.names.unique_resource_group_name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.this.id
}

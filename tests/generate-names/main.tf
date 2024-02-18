# tflint-ignore-file: terraform_standard_module_structure, terraform_variable_separate, terraform_output_separate, azurerm_resource_tag

variable "naming_suffix" {
  description = "The suffix to append to the names of the resources"
  type        = list(string)
  default     = ["automated-testing"]
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">=0.4.0"

  suffix = var.naming_suffix
}

output "unique_resource_group_name" {
  description = "Randomly generated name for a resource group"
  value       = module.naming.resource_group.name_unique
}

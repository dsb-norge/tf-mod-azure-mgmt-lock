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

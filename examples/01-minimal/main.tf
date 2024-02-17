provider "azurerm" {
  features {}
}

# tflint-ignore: azurerm_resource_tag
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = "example-resources"
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

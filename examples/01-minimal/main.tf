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

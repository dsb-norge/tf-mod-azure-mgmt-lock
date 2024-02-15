# tflint-ignore-file: azurerm_resource_tag

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  location = var.location
  name     = "example-resources"
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

module "prevent_resource_group_from_deletion" {
  source = "../../"

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

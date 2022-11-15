resource "azurerm_management_lock" "protected_resource_lock" {
  for_each   = var.protected_resources
  name       = "lock-${each.value.name}"
  scope      = each.value.id
  lock_level = each.value.lock_level != null ? each.value.lock_level : "CanNotDelete"
  notes      = <<-EOF
    ApplicationName: ${var.app_name}
    CreatedBy: ${var.created_by}
    Description: ${each.value.lock_level} lock for ${each.value.name}
  EOF
}

resource "azurerm_management_lock" "protected_resource_lock" {
  for_each = var.protected_resources

  lock_level = coalesce(each.value.lock_level, "CanNotDelete")
  name       = "lock-${each.value.name}"
  scope      = each.value.id
  notes      = <<-EOF
    ApplicationName: ${var.app_name}
    CreatedBy: ${var.created_by}
    Description: ${coalesce(each.value.lock_level, "CanNotDelete")} lock for ${each.value.name}
  EOF
}

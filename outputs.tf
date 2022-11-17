output "management_lock_ids" {
  description = "ids of the the management locks created by this module"
  value       = [for lock in azurerm_management_lock.protected_resource_lock : lock.id]
}

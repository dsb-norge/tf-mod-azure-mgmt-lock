output "management_locks" {
  description = "the management locks created by this module"
  value       = azurerm_management_lock.protected_resource_lock
}

output "management_lock_ids" {
  description = "this module produces a single output: the ids of the the management locks created"
  value       = module.prevent_resource_group_from_deletion.management_lock_ids
}

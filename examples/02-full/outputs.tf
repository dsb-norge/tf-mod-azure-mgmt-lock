output "management_lock_ids" {
  description = "this module produces a single output: the ids of the the management locks created"
  value       = module.lock_multiple_resources.management_lock_ids
}

variable "app_name" {
  description = "Name of application/domain using resources"
  type        = string
  nullable    = false
}

variable "created_by" {
  description = "The terraform project managing the lock(s)"
  type        = string
  nullable    = false
}

variable "protected_resources" {
  description = "Map with configuration of what resources to lock and how."
  type = map(object({
    id : string,
    name : string,
    lock_level : optional(string),
    description : optional(string),
  }))
  validation {
    condition = alltrue([
      for res in var.protected_resources : res.lock_level == null ? true : contains(["ReadOnly", "CanNotDelete"], res.lock_level)
    ])
    error_message = "lock_level, if not omitted, may only be one of [ReadOnly, CanNotDelete]"
  }
}

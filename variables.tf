variable "protected_resources" {
  description = "map of scope (URN/ID) and name for resources that should have a CanNotDelete lock"
  type = map(object({
    id : string,
    name : string,
    lock_level : optional(string),
  }))
  validation {
    condition = alltrue([
      for res in var.protected_resources : res.lock_level == null ? true : contains(["ReadOnly", "CanNotDelete"], res.lock_level)
    ])
    error_message = "lock_level, if not omitted, may only be one of [ReadOnly, CanNotDelete]"
  }
}

variable "app_name" {
  description = "Name of application/domain using resources"
  type        = string
  default     = "<unknown>"
}

variable "created_by" {
  description = "the tf project managing the lock(s)"
  type        = string
  default     = "<unknown>"
}

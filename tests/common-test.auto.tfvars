# inputs for tests
location   = "norwayeast"
app_name   = "my-app-name"
created_by = "https://github.com/my-org/my-tf-project"
protected_resources = {
  lock_1 = {
    id          = "/azure/id1/string"
    name        = "name-of-resource"
    lock_level  = "CanNotDelete"
    description = "This is a can-not-delete lock for the resource"
  }
  lock_2 = {
    id          = "/azure/id2/string"
    name        = "name-of-other-resource"
    lock_level  = "ReadOnly"
    description = "This is a read-only lock for the resource"
  }
}

# used in assertions
_test_expect_attributes = {
  default_lock_level = "CanNotDelete"
  lock_1 = {
    scope = "/azure/id1/string"
    name  = "lock-name-of-resource"
  }
  lock_2 = {
    scope = "/azure/id2/string"
    name  = "lock-name-of-other-resource"
  }
}

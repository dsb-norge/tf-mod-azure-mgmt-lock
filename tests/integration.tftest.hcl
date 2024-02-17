# integration.tftest.hcl

# lock actual resources

# verify output ids actually exists as resource locks

# use examples to verify the module works as expected


provider "azurerm" {
  features {}
}

# creates a resource group with a random name
run "setup" {
  command = apply

  module {
    source = "./tests/setup-resource-group"
  }
}

run "apply" {
  command = apply

  variables {
    protected_resources = {
      lock_1 = {
        id          = run.setup.resource_group_id
        name        = "do-not-delete-my-resource-group"
        lock_level  = "CanNotDelete"
        description = "This is a can-not-delete lock for the resource"
      }
      lock_2 = {
        id          = run.setup.resource_group_id
        name        = "you-can-only-read-my-resource-group"
        lock_level  = "ReadOnly"
        description = "This is a read-only lock for the resource"
      }
    }
  }

  # verify expected number of ids in output
  assert {
    condition     = length(output.management_lock_ids) == length(var.protected_resources)
    error_message = <<-ERROR
      Expected ${length(var.protected_resources)} lock resource ids in output, got ${length(output.management_lock_ids)}:
      %{for item in output.management_lock_ids~}
      ${~" - "}${item}
      %{endfor~}
    ERROR
  }
}

run "verify" {
  command = apply

  variables {
    management_lock_ids = run.apply.management_lock_ids
  }

  module {
    source = "./tests/read-resource-locks"
  }

  assert {
    condition     = length(output.map_of_locks) == 1
    error_message = <<-ERROR
      map_of_locks:
      %{for item in output.map_of_locks~}
      ${~" - "}${join(", ", [for key, value in item : "${key}=${value}"])}
      %{endfor~}
    ERROR
  }
}


# attempt to apply examples, verify ouputs

provider "azurerm" {
  features {}
}

variables {
  location = "norwayeast"
}

# generate names for resources
run "setup" {
  command = apply

  module {
    source = "./tests/generate-names"
  }
}

# apply example directory as a module
run "apply" {
  command = apply

  variables {
    resource_group_name = run.setup.unique_resource_group_name
  }

  module {
    source = "./examples/02-full"
  }

  # verify there are lock ids in output
  assert {
    condition     = length(output.management_lock_ids) > 0
    error_message = "Expected at least one lock resource id in output, got none"
  }
}

# we read back the resource lock(s) to verify they were created as expected
run "verify" {
  command = apply

  # use resource lock ids from apply step
  variables {
    management_lock_ids = run.apply.management_lock_ids
  }

  # read back info about lock resources
  module {
    source = "./tests/read-resource-locks"
  }

  # verify there are lock ids in output
  assert {
    condition     = length(output.map_of_locks) > 0
    error_message = "Expected at least one lock resource id in output, got none"
  }
}

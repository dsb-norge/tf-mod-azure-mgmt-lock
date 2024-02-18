provider "azurerm" {
  features {}
}

# variables, see common-test.auto.tfvars

# creates a resource group with a random name
run "setup" {
  command = apply

  module {
    source = "./tests/setup-resource-group"
  }
}

# create lock resources
run "apply" {
  command = apply

  # override values from common-test.auto.tfvars because we need to specify
  # the resource id for the resource group as the resource to lock
  variables {
    protected_resources = { for lock_name, lock_spec in var.protected_resources :
      lock_name => merge(lock_spec, {
        id = run.setup.resource_group_id
    }) }
  }

  # verify expected number of lock ids in output
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

# we read back the resource locks to verify they were created as expected
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

  # verify that expected lock names exist
  assert {
    condition = alltrue([for cfg_name, cfg in var.protected_resources :
      can(output.map_of_locks[var._test_expect_attributes[cfg_name].name])
    ])
    error_message = <<-ERROR
      Unable to find all expected lock names:
      %{for item in [for cfg_name, cfg in var.protected_resources : "Could not find expected name '${var._test_expect_attributes[cfg_name].name}' defined for lock configuration '${cfg_name}'" if !can(output.map_of_locks[var._test_expect_attributes[cfg_name].name])]~}
      ${~" - "}${item}
      %{endfor~}
      ERROR
  }

  # verify expected lock level
  assert {
    condition = alltrue([for cfg_name, cfg in var.protected_resources :
      can(output.map_of_locks[var._test_expect_attributes[cfg_name].name]) ?
      output.map_of_locks[var._test_expect_attributes[cfg_name].name].level == cfg.lock_level :
      false # if the lock does not exist, fail the test
    ])
    error_message = "Not all lock levels matched expected value"
  }

  # verify expected notes: Description
  #   require the input description to be in the notes
  assert {
    condition = alltrue([for cfg_name, cfg in var.protected_resources :
      can(output.map_of_locks[var._test_expect_attributes[cfg_name].name]) ?
      strcontains(output.map_of_locks[var._test_expect_attributes[cfg_name].name].notes, cfg.description) :
      false # if the lock does not exist, fail the test
    ])
    error_message = "Description not found within all notes attributes"
  }

  # verify expected  notes: ApplicationName
  #   require the input app_name to be in the notes
  assert {
    condition = alltrue([for cfg_name, cfg in var.protected_resources :
      can(output.map_of_locks[var._test_expect_attributes[cfg_name].name]) ?
      strcontains(output.map_of_locks[var._test_expect_attributes[cfg_name].name].notes, var.app_name) :
      false # if the lock does not exist, fail the test
    ])
    error_message = "Application name '${var.app_name}' not found within all notes attributes"
  }

  # verify expected notes: CreatedBy
  #   require the input created_by to be in the notes
  assert {
    condition = alltrue([for cfg_name, cfg in var.protected_resources :
      can(output.map_of_locks[var._test_expect_attributes[cfg_name].name]) ?
      strcontains(output.map_of_locks[var._test_expect_attributes[cfg_name].name].notes, var.created_by) :
      false # if the lock does not exist, fail the test
    ])
    error_message = "Created by '${var.created_by}' not found within all notes attributes"
  }
}

# add read only lock, attempt to create and expect error

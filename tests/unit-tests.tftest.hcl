provider "azurerm" {
  features {}
}

mock_provider "azurerm" {
  alias = "mock"
}

# variables, see common-test.auto.tfvars

run "it_should_allow_lock_level_readonly_and_cannotdelete" {
  command = plan
}

run "it_should_block_unsupported_lock_level" {
  command = plan

  variables {
    protected_resources = {
      lock_1 = {
        id          = "/azure/id1/string"
        name        = "name-of-resource"
        lock_level  = "ThisIsNotSupported"
        description = "This is a can-not-delete lock for the resource"
      }
    }
  }

  expect_failures = [
    var.protected_resources,
  ]
}

run "it_should_have_input_lock_level_as_optional" {
  command = plan

  variables {
    protected_resources = {
      lock_1 = {
        id          = "/azure/id1/string"
        name        = "name-of-resource"
        description = "This is a can-not-delete lock for the resource"
      }
    }
  }
}

run "it_should_default_to_lock_level_cannotdelete" {
  command = plan

  variables {
    protected_resources = {
      lock_1 = {
        id          = "/azure/id1/string"
        name        = "name-of-resource"
        description = "This is a can-not-delete lock for the resource"
      }
    }
  }

  # verify expected lock level
  assert {
    condition     = azurerm_management_lock.protected_resource_lock["lock_1"].lock_level == var._test_expect_attributes.default_lock_level
    error_message = "Default lock level was expected to be 'CanNotDelete' was '${azurerm_management_lock.protected_resource_lock["lock_1"].lock_level}'"
  }
}

run "it_should_have_input_description_as_optional" {
  command = plan

  variables {
    protected_resources = {
      lock_1 = {
        id         = "/azure/id1/string"
        name       = "name-of-resource"
        lock_level = "CanNotDelete"
      }
    }
  }
}

run "it_should_set_expected_attributes_on_lock_resources" {
  command = plan

  # verify expected scopes
  assert {
    condition = alltrue([for name, spec in var.protected_resources :
      azurerm_management_lock.protected_resource_lock[name].scope == var._test_expect_attributes[name].scope
    ])
    error_message = <<-ERROR
      Not all lock names matched expected value:
      %{for item in [for name, spec in var.protected_resources : "${name}: should be '${var._test_expect_attributes[name].scope}' was '${azurerm_management_lock.protected_resource_lock[name].scope}'" if azurerm_management_lock.protected_resource_lock[name].scope != var._test_expect_attributes[name].scope]~}
      ${~" - "}${item}
      %{endfor~}
      ERROR
  }

  # verify expected lock names
  assert {
    condition = alltrue([for name, spec in var.protected_resources :
      azurerm_management_lock.protected_resource_lock[name].name == var._test_expect_attributes[name].name
    ])
    error_message = <<-ERROR
      Not all lock names matched expected value:
      %{for item in [for name, spec in var.protected_resources : "${name}: should be '${var._test_expect_attributes[name].name}' was '${azurerm_management_lock.protected_resource_lock[name].name}'" if azurerm_management_lock.protected_resource_lock[name].name != var._test_expect_attributes[name].name]~}
      ${~" - "}${item}
      %{endfor~}
      ERROR
  }

  # verify expected lock levels
  assert {
    condition = alltrue([for name, spec in var.protected_resources :
      azurerm_management_lock.protected_resource_lock[name].lock_level == var.protected_resources[name].lock_level
    ])
    error_message = <<-ERROR
      Not all lock levels matched expected value:
      %{for item in [for name, spec in var.protected_resources : "${name}: should be '${var.protected_resources[name].lock_level}' was '${azurerm_management_lock.protected_resource_lock[name].lock_level}'" if azurerm_management_lock.protected_resource_lock[name].lock_level != var.protected_resources[name].lock_level]~}
      ${~" - "}${item}
      %{endfor~}
      ERROR
  }

  # verify notes is defined and has content
  assert {
    condition = alltrue([for name, spec in var.protected_resources :
      length(azurerm_management_lock.protected_resource_lock[name].notes) > 0
    ])
    error_message = <<-ERROR
      Not all lock resource had notes defined:
      %{for item in [for name, spec in var.protected_resources : "${name}: 'notes' was empty" if length(azurerm_management_lock.protected_resource_lock[name].notes) == 0]~}
      ${~" - "}${item}
      %{endfor~}
      ERROR
  }
}

run "it_should_output_one_lock_resource_id_per_protected_resource" {
  command = apply

  providers = {
    azurerm = azurerm.mock
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

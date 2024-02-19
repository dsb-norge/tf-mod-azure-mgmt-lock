# tf-mod-azure-mgmt-lock

Terraform module for adding [management locks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) to resources.

## required arguments

`scope` - the id (URN) wherefore to create the lock. This can be a subscription, resource group or resource.

`name` - name of the lock. Must be unique scope-wide, will be prefixed by `lock-`.

## optional arguments

`lock_level` - [lock level](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock#lock_level), defaults to `CanNotDelete`.

## Example

```hcl
provider "azurerm" {
  features {}
}

module "resource_deletion_locks" {
  source              = "git@github.com:dsb-norge/tf-mod-azure-mgmt-lock.git?ref=v0"
  protected_resources = {
    "scope-unique-resource-name" = {
      "id"         = provider_resource.my_resource.id
      "name"       = provider_resource.my_resource.name
      "lock_level" = "CanNotDelete"
    }
  }
  app_name   = "CanNotDelete locks for k8s resources"
  created_by = "https://github.com/my-org/my-tf-project"
}
```

## Versioning

This module uses [semantic versioning](https://semver.org).

## Development

### Validate your code

```shell
  # Init project, run fmt and validate
  terraform init -reconfigure
  terraform fmt -check -recursive
  terraform validate

  # Lint with TFLint, calling script from https://github.com/dsb-norge/terraform-tflint-wrappers
  alias lint='curl -s https://raw.githubusercontent.com/dsb-norge/terraform-tflint-wrappers/main/tflint_linux.sh | bash -s --'
  lint
```

### Generate and inject terraform-docs in README.md

```shell
# go1.17+
go install github.com/terraform-docs/terraform-docs@v0.18.0
export PATH=$PATH:$(go env GOPATH)/bin

# root
terraform-docs markdown table --output-file README.md .

# docs for examples
for ex_dir in $(find "./examples" -maxdepth 1 -mindepth 1 -type d | sort); do
  terraform-docs markdown document "${ex_dir}" --config ./examples/.terraform-docs.yml
done
```

### Release

After merge of PR to main use tags to release.

Use semantic versioning, see [semver.org](https://semver.org/). Always push tags and add tag annotations.

Example of patch release `v0.0.4`:

```bash
git checkout origin/main
git pull origin main
git tag -a 'v0.0.4'  # add patch tag, add change description
git tag -f -a 'v0.0' # move the minor tag, amend the change description
git tag -f -a 'v0'   # move the major tag, amend the change description
git push -f --tags   # force push the new tags
```

Example of major release `v1.0.0`:

```bash
git checkout origin/main
git pull origin main
git tag -a 'v1.0.0'  # add patch tag, add your change description
git tag -a 'v1.0'    # add minor tag, add your change description
git tag -a 'v0'      # add major tag, add your change description
git push --tags      # push the new tags
```

**Note:** If you are having problems pulling main after a release, try to force fetch the tags: `git fetch --tags -f`.

## terraform-docs


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.0.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_management_lock.protected_resource_lock](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Name of application/domain using resources | `string` | n/a | yes |
| <a name="input_created_by"></a> [created\_by](#input\_created\_by) | The terraform project managing the lock(s) | `string` | n/a | yes |
| <a name="input_protected_resources"></a> [protected\_resources](#input\_protected\_resources) | Map with configuration of what resources to lock and how. | <pre>map(object({<br>    id : string,<br>    name : string,<br>    lock_level : optional(string),<br>    description : optional(string),<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_management_lock_ids"></a> [management\_lock\_ids](#output\_management\_lock\_ids) | ids of the the management locks created by this module |
<!-- END_TF_DOCS -->

#!/usr/bin/env bash

set -euo pipefail

# causes terraform commands to behave as if the -input=false flag was specified.
export TF_INPUT=0

# non-empty value causes terraform to adjust its output to avoid suggesting specific commands to run next
export TF_IN_AUTOMATION=1

# azurem provider configuration
export ARM_TENANT_ID='goes here'
export ARM_SUBSCRIPTION_ID='goes here'

terraform init
terraform test
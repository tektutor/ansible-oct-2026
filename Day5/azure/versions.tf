terraform {
  required_version = ">= 1.4.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

# The provider reads its credentials from these environment variables:
#   ARM_SUBSCRIPTION_ID, ARM_TENANT_ID (plus ARM_CLIENT_ID, ARM_CLIENT_SECRET
#   for a service principal). With a user account it uses the Azure CLI session.
# run.sh reads everything from the Ansible Vault file.
# No Azure credential is written in any .tf file or in the Terraform state.
provider "azurerm" {
  features {}

  # Lab accounts cannot register resource providers, so skip that step
  # when deploying into an existing resource group.
  resource_provider_registrations = var.existing_resource_group_name == null ? "core" : "none"
}

terraform {
  required_version = ">= 1.2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    # terraform_data is built into Terraform 1.4+, no provider needed
  }
}

# Configure the AzureRM provider.  The features block enables a number of
# optional capabilities without any additional configuration.  See the
# provider documentation for more details.
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
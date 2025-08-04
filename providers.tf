terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.38.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1, < 4.0.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "7b051460-2177-4fee-9e29-752f78e6ecb1"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {
  # Azure AD provider configuration
  # Uses the same authentication as the AzureRM provider
}
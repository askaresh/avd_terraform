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
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  # subscription_id is supplied via the ARM_SUBSCRIPTION_ID environment variable
  # set by running .\set-auth.ps1 before any terraform commands
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

provider "azapi" {
  # AzAPI provider configuration
  # Uses the same authentication as the AzureRM provider
  # Required for session host cleanup during destroy operations
}
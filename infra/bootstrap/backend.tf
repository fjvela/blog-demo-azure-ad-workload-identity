terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.11.0"
    }

    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.4"
}

provider "azurerm" {
  subscription_id     = var.azure_subscription_id
  storage_use_azuread = true

  resource_providers_to_register = [
    "Microsoft.ManagedIdentity",
    "Microsoft.Storage",
  ]

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "github" {
  owner = var.github_organization_name
  token = var.github_token
}


data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }

  # storage_account_name is created by infra/bootstrap: tofu init -backend-config="storage_account_name=<name>"
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "infra.tfstate"
    use_azuread_auth = true
  }
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.4"
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id

  resource_providers_to_register = [
    "Microsoft.ContainerRegistry",
    "Microsoft.ContainerService",
    "Microsoft.KeyVault",
    "Microsoft.ManagedIdentity",
  ]

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

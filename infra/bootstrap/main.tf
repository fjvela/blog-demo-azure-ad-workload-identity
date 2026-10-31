resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name_unique
  location = local.region
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "uid" {
  name                = "gh-${var.github_organization_name}-${var.github_repository_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "federated_identity_credential" {
  for_each                  = toset(var.branches)
  name                      = "gh-${var.github_organization_name}-${var.github_repository_name}-${each.value}"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.uid.id
  subject                   = "repo:${var.github_organization_name}/${var.github_repository_name}:ref:refs/heads/${each.value}"
}

# The pipeline creates the resource group of infra/azure, so it needs access to the whole subscription
resource "azurerm_role_assignment" "uid_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.uid.principal_id
  principal_type       = "ServicePrincipal"
}

# infra/azure grants AcrPull to the AKS kubelet identity, no other role can be assigned or removed
resource "azurerm_role_assignment" "uid_rbac_administrator" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.uid.principal_id
  principal_type       = "ServicePrincipal"
  condition_version    = "2.0"
  condition            = <<-EOT
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
      )
      OR
      (
        @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.acr_pull_role_definition_id}}
      )
    )
    AND
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
      )
      OR
      (
        @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.acr_pull_role_definition_id}}
      )
    )
  EOT
}

# Remote state of infra/azure
resource "azurerm_storage_account" "tfstate" {
  name                            = module.naming.storage_account.name_unique
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  name               = "tfstate"
  storage_account_id = azurerm_storage_account.tfstate.id
}

resource "azurerm_role_assignment" "uid_tfstate" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.uid.principal_id
  principal_type       = "ServicePrincipal"
}

# Allows running infra/azure locally (e.g. to migrate the local state)
resource "azurerm_role_assignment" "current_tfstate" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# GitHub Setup
data "github_repository" "this" {
  name = var.github_repository_name
}

resource "github_actions_secret" "azure_client_id" {
  repository      = data.github_repository.this.name
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = azurerm_user_assigned_identity.uid.client_id
}

resource "github_actions_secret" "azure_tenant_id" {
  repository      = data.github_repository.this.name
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = data.azurerm_subscription.current.tenant_id
}

resource "github_actions_secret" "azure_subscription_id" {
  repository      = data.github_repository.this.name
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = data.azurerm_subscription.current.subscription_id
}

resource "github_actions_variable" "tf_state_storage_account_name" {
  repository    = data.github_repository.this.name
  variable_name = "TF_STATE_STORAGE_ACCOUNT_NAME"
  value         = azurerm_storage_account.tfstate.name
}

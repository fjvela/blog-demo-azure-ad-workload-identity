output "tf_state_storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "github_identity_principal_id" {
  value = azurerm_user_assigned_identity.uid.principal_id
}

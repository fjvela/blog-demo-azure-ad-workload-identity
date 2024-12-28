resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name_unique
  location = local.region
  tags     = local.tags
}

resource "azurerm_container_registry" "acr" {
  name                = module.naming.container_registry.name_unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  admin_enabled       = true
  tags                = local.tags
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = module.naming.kubernetes_cluster.name_unique
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  dns_prefix                = module.naming.kubernetes_cluster.name_unique
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "azurerm_role_assignment_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  skip_service_principal_aad_check = true
}

resource "azurerm_user_assigned_identity" "uid" {
  name                = "aks-app-1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "federated_identity_credential" {
  name                = "aks"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.uid.id
  subject             = "system:serviceaccount:develop:sa-app-1"
}

resource "azurerm_key_vault" "kv" {
  name                        = module.naming.key_vault.name_unique
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = var.kv.enabled_for_disk_encryption
  soft_delete_retention_days  = var.kv.soft_delete_retention_days
  purge_protection_enabled    = var.kv.purge_protection_enabled
  sku_name                    = var.kv.sku_name

  access_policy {
    tenant_id = azurerm_user_assigned_identity.uid.tenant_id
    object_id = azurerm_user_assigned_identity.uid.principal_id

    secret_permissions = [
      "Get",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete",
      "Recover",
      "Purge"
    ]
  }

  depends_on = [
    azurerm_user_assigned_identity.uid
  ]
}

resource "random_password" "random_secret" {
  length  = var.kv_secret.length
  special = var.kv_secret.special
}

resource "azurerm_key_vault_secret" "kv_secret" {
  name         = var.kv_secret.name
  value        = random_password.random_secret.result
  key_vault_id = azurerm_key_vault.kv.id
}



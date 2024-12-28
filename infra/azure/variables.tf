variable "azure_subscription_id" {
  description = "The Azure subscription ID where the resources will be deployed"
}

variable "kv" {
  default = {
    enabled_for_disk_encryption = true
    soft_delete_retention_days  = 7
    purge_protection_enabled    = false
    sku_name                    = "standard"
  }
}

variable "kv_secret" {
  default = {
    name    = "secret-sauce"
    length  = 32
    special = true
  }
}

variable "azure_subscription_id" {
  description = "The Azure subscription ID where the resources will be deployed"
}

variable "github_organization_name" {
  description = "Name of the GitHub organization"
  default     = "fjvela"
}

variable "branches" {
  description = "List of git branches to add as subject to the federated identity credential"
  default = [
    "main"
  ]
}

variable "github_repository_name" {
  description = "Name of the repository to setup the secrets needed"
  default     = "blog-demo-azure-ad-workload-identity"
}

variable "github_token" {
  description = "GitHub token with permissions to manage repository secrets and variables"
  type        = string
  sensitive   = true
}

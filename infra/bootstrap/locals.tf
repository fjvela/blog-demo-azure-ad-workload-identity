locals {
  region = "West Europe"

  tags = {
    "project" = "demo federated identity credentials"
  }

  # Built-in AcrPull role: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/containers#acrpull
  acr_pull_role_definition_id = "7f951dda-4ed3-4680-a7ca-43fe172d538d"
}

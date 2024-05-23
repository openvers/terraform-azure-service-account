terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "sim-parables"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ci-cd-azure-workspace"
    }
  }
}

##---------------------------------------------------------------------------------------------------------------------
## AZUREAD PROVIDER
##
## Azure Active Directory (AzureAD) provider authenticated with CLI.
##---------------------------------------------------------------------------------------------------------------------
provider "azuread" {
  alias = "tokengen"
}

##---------------------------------------------------------------------------------------------------------------------
## AZURRM PROVIDER
##
## Azure Resource Manager (Azurerm) provider authenticated with CLI.
##---------------------------------------------------------------------------------------------------------------------
provider "azurerm" {
  alias = "tokengen"
  features {}
}

locals {
  oidc_subject = [
    {
      display_name = "example-federated-idp-readwrite"
      subject      = "repo:${var.GITHUB_REPOSITORY}:environment:${var.GITHUB_ENV}"
    },
    {
      display_name = "example-federated-idp-read"
      subject      = "repo:${var.GITHUB_REPOSITORY}:ref:${var.GITHUB_REF}"
    }
  ]
}

data "azurerm_client_config" "current" {
  provider = azurerm.tokengen
}

##---------------------------------------------------------------------------------------------------------------------
## AZURE SERVICE ACCOUNT MODULE
##
## This module provisions an Azure service account along with associated roles and security groups.
##
## Parameters:
## - `application_display_name`: The display name of the Azure application.
## - `role_name`: The name of the role for the Azure service account.
## - `security_group_name`: The name of the security group.
##---------------------------------------------------------------------------------------------------------------------
module "azure_service_account" {
  source     = "../"
  depends_on = [data.azurerm_client_config.current]

  application_display_name = var.application_display_name
  role_name                = var.role_name
  security_group_name      = var.security_group_name

  providers = {
    azuread.tokengen = azuread.tokengen
    azurerm.tokengen = azurerm.tokengen
  }
}


##---------------------------------------------------------------------------------------------------------------------
## AZURE APPLICATION IDENTITY FEDERATION CREDENTIALS MODULE
##
## This module creates a Federated Identity Credential for the application to authenticate with Github Actions
## without client credetials through OpenID Connect protocol.
##
## Parameters:
## - `application_id`: Azure service account application ID.
## - `display_name`: Identity Federation Credential display name.
## - `subject`: OIDC authentication subject.
##---------------------------------------------------------------------------------------------------------------------
module "azure_application_federated_identity_credential" {
  source     = "../modules/identity_federation"
  depends_on = [module.azure_service_account]
  for_each   = tomap({ for t in local.oidc_subject : "${t.display_name}-${t.subject}" => t })

  application_id = module.azure_service_account.application_id
  display_name   = each.value.display_name
  subject        = each.value.subject

  providers = {
    azuread.auth_session = azuread.tokengen
  }
}
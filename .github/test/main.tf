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

##---------------------------------------------------------------------------------------------------------------------
## AZURE SERVICE ACCOUNT MODULE
##
## This module provisions an Azure service account along with associated roles and security groups.
##
## Parameters:
## - `application_display_name`: The display name of the Azure application.
## - `role_name`: The name of the role for the Azure service account.
## - `security_group_name`: The name of the security group.
##
## Providers:
## - `azuread.tokengen`: Alias for the Azure AD provider for generating tokens.
## - `azurerm.tokengen`: Alias for the Azure Resource Manager (Azurerm) provider for generating tokens.
##---------------------------------------------------------------------------------------------------------------------
module "azure_service_account" {
  source  = "../../"

  application_display_name = var.application_display_name
  role_name                = var.role_name
  security_group_name      = var.security_group_name

  providers = {
    azuread.tokengen = azuread.tokengen
    azurerm.tokengen = azurerm.tokengen
  }
}
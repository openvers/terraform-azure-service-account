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
  alias = "auth_session"
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
  source   = "../../modules/identity_federation"
  for_each = tomap({ for t in local.oidc_subject : "${t.display_name}-${t.subject}" => t })

  application_id = var.APPLICATION_ID
  display_name   = each.value.display_name
  subject        = each.value.subject

  providers = {
    azuread.auth_session = azuread.auth_session
  }
}
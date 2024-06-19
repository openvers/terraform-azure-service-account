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
      name = "ci-cd-azure-service-account-workspace"
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

data "azuread_application_published_app_ids" "this" {
  provider = azuread.tokengen
}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.this.result["MicrosoftGraph"]
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

  api_permissions = [
    {
      resource_app_id    = data.azuread_application_published_app_ids.this.result["MicrosoftGraph"]
      resource_object_id = data.azuread_service_principal.msgraph.object_id
      scope_ids          = []
      role_ids = [
        data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"],
        data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.OwnedBy"],
        data.azuread_service_principal.msgraph.app_role_ids["AppRoleAssignment.ReadWrite.All"],
        data.azuread_service_principal.msgraph.app_role_ids["Directory.ReadWrite.All"],
        data.azuread_service_principal.msgraph.app_role_ids["User.Read.All"],
        data.azuread_service_principal.msgraph.app_role_ids["Group.ReadWrite.All"],
      ]
    }
  ]

  app_roles = [
    {
      allowed_member_types = ["User"]
      description          = "Test App Role"
      display_name         = "Administrator"
      value                = "admin"
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
## - `api_permissions`: List of API permissions to grant to Azure Application.
## - `role_name`: The name of the role for the Azure service account.
## - `security_group_name`: The name of the security group.
##---------------------------------------------------------------------------------------------------------------------
module "azure_service_account" {
  source     = "../"
  depends_on = [data.azurerm_client_config.current]

  application_display_name = var.application_display_name
  api_permissions          = local.api_permissions
  security_group_name      = var.security_group_name
  role_name                = var.role_name
  application_app_roles    = local.app_roles

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
  source   = "../modules/identity_federation"
  for_each = tomap({ for t in local.oidc_subject : "${t.display_name}-${t.subject}" => t })

  application_id = module.azure_service_account.application_id
  display_name   = each.value.display_name
  subject        = each.value.subject

  providers = {
    azuread.tokengen = azuread.tokengen
  }
}
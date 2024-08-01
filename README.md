<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Microsoft_Azure-0089D6?style=for-the-badge&logo=microsoft-azure&logoColor=white" height="25px"/>
  <img id="b-2" src="https://img.shields.io/github/actions/workflow/status/sim-parables/terraform-azure-service-account/tf-integration-test.yml?style=flat&logo=github&label=CD%20(August%202024)" height="25px"/>
</p>

# Terraform Azure Service Account

A reusable module for creating Service Accoounts with limited privileges for both Development and Production purposes.

## Usage

```hcl
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
  source  = "github.com/sim-parables/terraform-azure-service-account"

  application_display_name = "example-service-account"
  role_name                = "example-service-account-role"
  security_group_name      = "example-group"

  providers = {
    azuread.tokengen = azuread.tokengen
    azurerm.tokengen = azurerm.tokengen
  }
}

```

## Inputs

| Name                     | Description                             | Type         | Default | Required |
|:-------------------------|:----------------------------------------|:-------------|:--------|:---------|
| application_display_name | Service Account AD Application Name     | string       | N/A     | Yes      |
| role_name                | Service Account Role Name               | string       | N/A     | Yes      |
| security_group_name      | Security Group Name                     | string       | N/A     | Yes      |
| roles_list               | List of Permitted Service Account Roles | list(string) | []      | No       |
| client_secret_expiration | Client Secret Expiration in Hours       | string       | 169h    | No       |
| tags                     | Azure Resource Tag(s)                   | map()        | {}      | No       |
| application_template_id  | Azure Gallery App Template ID           | string       | null    | No       |

## Outputs

| Name              | Description                          |
|:------------------|:-------------------------------------|
| client_id         | Azure Service Principal Client ID    |
| client_secret_key | Azure Service Principal Secret ID    |
| client_secret     | Azure Service Principal Secret       |
| security_group_id | Azure AD Superhero Security Group ID |

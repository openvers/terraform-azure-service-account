terraform {
  required_providers {
    random = "~> 2.2"
    azuread = {
      source = "hashicorp/azuread"
      configuration_aliases = [
        azuread.auth_session,
      ]
    }
  }
}

locals {
  cloud   = "azure"
  program = "service-account"
  project = "idp"
}


## ---------------------------------------------------------------------------------------------------------------------
## AZUREAD APPLICATION FEDERATED IDENTITY CREDENTIAL RESOURCE
##
## This resource creates a Federated Identity Credential for the application to authenticate with Github Actions
## without client credetials through OpenID Connect protocol.
##
## Parameters:
## - `application_id`: The Application ID of the service principal.
## - `display_name`: Application Federated Identitiy credentials display name.
## - `description`: Application Federated Identitiy credentials description.
## - `audiences`: List of OIDC audiences.
## - `issues`: name of the OIDC issuer.
## - `subject`: OIDC subject line to allow authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "azuread_application_federated_identity_credential" "this" {
  provider = azuread.auth_session

  application_id = var.application_id
  display_name   = var.display_name
  description    = var.description
  audiences      = var.audiences
  issuer         = var.issuer
  subject        = var.subject
}
/* Service Account Auth Module

Create an Azuure Service Principal to manage resouces when MSI isn't an option
List of Resource Provider Operations found here
https://learn.microsoft.com/en-ca/azure/role-based-access-control/resource-provider-operations
*/
terraform {
  required_providers {
    random = "~> 2.2"
    azuread = {
      source = "hashicorp/azuread"
      configuration_aliases = [
        azuread.tokengen,
      ]
    }
    azurerm = {
      source = "hashicorp/azurerm"
      configuration_aliases = [
        azurerm.tokengen,
      ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURERM SUBSCRIPTION DATA SOURCE
##
## This data source retrieves information about the primary Azure subscription.
## ---------------------------------------------------------------------------------------------------------------------
data "azurerm_subscription" "primary" {
  provider = azurerm.tokengen
}


## ---------------------------------------------------------------------------------------------------------------------
## AZUREAD CLIENT CONFIGURATION DATA SOURCE
##
## This data source retrieves the current Azure Active Directory (Azure AD) client configuration.
## ---------------------------------------------------------------------------------------------------------------------
data "azuread_client_config" "current" {
  provider = azuread.tokengen
}


## ---------------------------------------------------------------------------------------------------------------------
## RANDOM UUID RESOURCE
##
## This resource generates a random UUID (Universally Unique Identifier).
## ---------------------------------------------------------------------------------------------------------------------
resource "random_uuid" "this" {}


## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

locals {
  cloud   = "azure"
  program = "service-account"
  project = "cloud-auth"
}

locals {
  suffix = "${random_string.this.id}-${local.program}-${local.project}"
  roles_list = distinct(concat(var.roles_list, [
    "Microsoft.Resources/subscriptions/providers/read",
    "Microsoft.Resources/subscriptions/resourceGroups/*",
    "Microsoft.Authorization/roleAssignments/*",
    "Microsoft.Authorization/roleDefinitions/*"
  ]))

  app_role_assignments = flatten([
    for t in var.api_permissions : [
      for r in t.role_ids : {
        resource_object_id = t.resource_object_id
        role_id            = r
      }
    ]
  ])
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE ROLE DEFINITION RESOURCE
##
## This resource defines a custom Azure role with specific permissions.
##
## Parameters:
## - `role_name`: The name of the custom role.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_role_definition" "this" {
  provider = azurerm.tokengen

  role_definition_id = random_uuid.this.result
  name               = "${var.role_name}-${local.suffix}"
  scope              = data.azurerm_subscription.primary.id

  permissions {
    actions     = local.roles_list
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id,
  ]

  timeouts {
    delete = "1m"
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE ACTIVE DIRECTORY APPLICATION RESOURCE
##
## This resource represents an application registered in Azure Active Directory.
##
## Parameters:
## - `display_name`: The display name of the application.
## - `owners`: List of MS Entra ID to own the Azure application.
## - `template_id`: Azure Gallery App application template ID.
## ---------------------------------------------------------------------------------------------------------------------
resource "azuread_application" "this" {
  provider   = azuread.tokengen
  depends_on = [azurerm_role_definition.this]

  display_name = "${var.application_display_name}-${local.suffix}"
  template_id  = var.application_template_id
  owners       = [data.azuread_client_config.current.object_id]
}


resource "random_uuid" "app_roles" {
  count = length(var.application_app_roles)
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE ACTIVE DIRECTORY APPLICATION APP ROLE RESOURCE
##
## This resource binds and App Role configuration to the Azure application.
##
## Parameters:
## - `application_id`: Azure application ID.
## - `role_id`: Unique ID for App Role with UUID format.
## - `allowed_member_types`: List of MS Entra member types which the App role can be assigned to.
## - `description`: App Role description.
## - `display_name`: App Role display name.
## - `value`: App Role member value.
## ---------------------------------------------------------------------------------------------------------------------
resource "azuread_application_app_role" "this" {
  provider   = azuread.tokengen
  depends_on = [azuread_application.this]
  count      = length(var.application_app_roles)

  application_id       = azuread_application.this.id
  role_id              = random_uuid.app_roles[count.index].result
  allowed_member_types = var.application_app_roles[count.index].allowed_member_types
  description          = var.application_app_roles[count.index].description
  display_name         = var.application_app_roles[count.index].display_name
  value                = var.application_app_roles[count.index].value
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE ACTIVE DIRECTORY SERVICE PRINCIPAL RESOURCE
##
## This resource represents a service principal registered in Azure Active Directory.
##
## Parameters:
## - `client_id`: The client ID of the associated application.
## - `app_role_assignment_required`: Specifies whether the service principal requires an app role assignment.
## - `owners`: MS Entra members who own the service principal.
## - `use_existing`: Flag to declare if service principal already exists.
## ---------------------------------------------------------------------------------------------------------------------
resource "azuread_service_principal" "this" {
  provider   = azuread.tokengen
  depends_on = [azuread_application.this]

  client_id                    = azuread_application.this.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
  use_existing                 = var.application_template_id != null
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE ACTIVE DIRECTORY SERVICE PRINCIPAL PASSWORD RESOURCE
##
## This resource creates a password for an Azure Active Directory service principal.
##
## Parameters:
## - `service_principal_id`: The ID of the service principal for which the password is generated.
## - `end_date_relative`: The relative expiration date for the password.
## ---------------------------------------------------------------------------------------------------------------------
resource "azuread_service_principal_password" "this" {
  provider   = azuread.tokengen
  depends_on = [azuread_service_principal.this]

  service_principal_id = "/servicePrincipals/${azuread_service_principal.this.object_id}"
  end_date_relative    = var.client_secret_expiration
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE ACTIVE DIRECTORY APPLICATION API ACCESS RESOURCE
##
## This resource represents an application registered in Azure Active Directory.
##
## Parameters:
## - `application_id`: Azure Application ID.
## - `api_client_id`: MS Entra API ID.
## - `role_ids`: List Application API Permission RoleID.
## - `scope_ids`: List Application API Permission RoleID.
## ---------------------------------------------------------------------------------------------------------------------
resource "azuread_application_api_access" "this" {
  provider   = azuread.tokengen
  depends_on = [azuread_service_principal_password.this]
  for_each   = tomap({ for t in var.api_permissions : "${t.resource_app_id}" => t })

  application_id = azuread_application.this.id
  api_client_id  = each.value.resource_app_id
  role_ids       = each.value.role_ids
  scope_ids      = each.value.scope_ids
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE ACTIVE DIRECTORY APP ROLE ASSIGNMENT RESOURCE
##
## This resource provide admin grants to Azure Application API permissions.
##
## Parameters:
## - `principal_object_id`: Azure Application ID.
## - `resource_object_id`: MS Entra API object ID.
## - `app_role_id`: Application API Permission RoleID.
## ---------------------------------------------------------------------------------------------------------------------
resource "azuread_app_role_assignment" "this" {
  provider = azuread.tokengen
  for_each = tomap({ for t in local.app_role_assignments : "${t.resource_object_id}-${t.role_id}" => t })
  depends_on = [
    azuread_application_api_access.this,
    azuread_service_principal_password.this
  ]

  app_role_id         = each.value.role_id
  principal_object_id = azuread_service_principal.this.object_id
  resource_object_id  = each.value.resource_object_id
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE ACTIVE DIRECTORY GROUP RESOURCE
##
## This resource represents a group in Azure Active Directory.
##
## Parameters:
## - `display_name`: The display name of the group.
## - `owners`: A list of object IDs of users who are owners of the group.
## - `security_enabled`: Specifies whether the group is security-enabled.
## - `members`: A list of object IDs of users or service principals who are members of the group.
## ---------------------------------------------------------------------------------------------------------------------
resource "azuread_group" "this" {
  provider   = azuread.tokengen
  depends_on = [azuread_app_role_assignment.this]

  display_name     = "${var.security_group_name}-${local.suffix}"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = [
    data.azuread_client_config.current.object_id,
    azuread_service_principal.this.object_id
  ]
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE ROLE ASSIGNMENT RESOURCE
##
## This resource assigns a role to a security group in Azure.
##
## Parameters:
## - `name`: A name for the role assignment.
## - `scope`: The scope at which the role assignment is applied.
## - `role_definition_id`: The ID of the role definition to assign.
## - `principal_id`: The ID of the security group to which the role is assigned.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "this" {
  provider   = azurerm.tokengen
  depends_on = [azurerm_role_definition.this]

  name               = random_uuid.this.result
  scope              = data.azurerm_subscription.primary.id
  role_definition_id = azurerm_role_definition.this.role_definition_resource_id
  principal_id       = azuread_group.this.object_id
}

## ---------------------------------------------------------------------------------------------------------------------
## TIME SLEEP RESOURCE
##
## This resource defines a delay to allow time for Azure Service Principal access key propagation.
##
## Parameters:
## - `create_duration`: The duration for the time sleep.
## ---------------------------------------------------------------------------------------------------------------------
resource "time_sleep" "key_propogation" {
  depends_on = [
    azuread_service_principal_password.this,
    azurerm_role_assignment.this
  ]

  create_duration = "60s"
}

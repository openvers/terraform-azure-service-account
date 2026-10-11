## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "application_display_name" {
  type        = string
  description = "Service Account AD Application Name"
}

variable "role_name" {
  type        = string
  description = "Service Account Role Name"
}

variable "security_group_name" {
  type        = string
  description = "Security Group Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "roles_list" {
  type        = list(string)
  description = "List of Permitted Service Account Roles"
  default     = []
}

variable "client_secret_expiration" {
  type        = string
  description = "Service Account Secret Relative Expiration from Creation"
  default     = "169h"
}

variable "api_permissions" {
  description = "Azure Application Registration API Permissions to grant access"
  default     = []
  type = list(object({
    resource_app_id    = string
    resource_object_id = string
    role_ids           = list(string)
    scope_ids          = list(string)
  }))
}

variable "application_template_id" {
  type        = string
  description = "Azure Gallery App Template ID"
  default     = null
}

variable "application_app_roles" {
  description = "App Roles to bind to Application for Downstream Services"
  default     = null
  type = list(object({
    allowed_member_types = list(string)
    description          = string
    display_name         = string
    value                = string
  }))
}
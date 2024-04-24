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
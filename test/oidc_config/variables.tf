## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "APPLICATION_ID" {
  type        = string
  description = "Service Account AD Application ID"
  default     = "/applications/00000000-0000-0000-0000-000000000000"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "GITHUB_REPOSITORY_OWNER" {
  type        = string
  description = "Github Actions Default ENV Variable for the Repo Owner"
  default     = "sim-parables"
}

variable "GITHUB_REPOSITORY" {
  type        = string
  description = "Github Actions Default ENV Variable for the Repo Path"
  default     = "sim-parables/terraform-aws-service-account"
}

variable "GITHUB_REF" {
  type        = string
  description = "Github Actions Default ENV Variable for full form of the Branch or Tag"
  default     = null
}

variable "GITHUB_ENV" {
  type        = string
  description = <<EOT
    Github Environment in which the Action Workflow's Job or Step is running. Ex: production.
    This is not found in Github Action's Default Environment Variables and will need to be
    defined manually.
  EOT
  default     = null
}

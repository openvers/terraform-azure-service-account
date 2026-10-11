## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "application_id" {
  type        = string
  description = "Azure Application ID"
}

variable "subject" {
  type        = string
  description = "Azure Application Federated Identity OIDC Authentication Subject"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "display_name" {
  type        = string
  description = "Azure Application Federated Identity Display name"
  default     = "example-azure-federated-idp"
}

variable "description" {
  type        = string
  description = "Azure Application Federated Identity Descripiton"
  default     = "Example Azure Federated Indentity Credential"
}

variable "audiences" {
  type        = list(string)
  description = "Azure Application Federated Identity OIDC Audiencees"
  default     = ["api://AzureADTokenExchange"]
}

variable "issuer" {
  type        = string
  description = "Azure Application Federated Identity OIDC Issuer"
  default     = "https://token.actions.githubusercontent.com"
}
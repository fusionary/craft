#########
# Secrets
#########

variable "secrets_manager_access_key_id" {
  type        = string
  description = "Access key ID for secrets manager in AWS."
}

variable "secrets_manager_secret_key" {
  type        = string
  description = "Access key secret for secrets manager in AWS."
}


####################
# Client AWS Account
####################

#~~~~~#
# SES #
#~~~~~#

variable "ses_domain" {
  type        = string
  # @todo: If this is set to something other than an empty string, then the domain will be added as a verified identity.
  default     = ""
  description = "Domain to be validated for SES configuration."
}

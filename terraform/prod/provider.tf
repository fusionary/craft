terraform {
  backend "s3" {
    bucket = "fusionary-terraform-remote-backends"
    region = "us-east-1"
    # @todo: Set backend key for state storage (usually in the form of client/project/env.tfstate)
    key        = null
    access_key = null
    secret_key = null
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

###################################
# Fusionary Development AWS Account
###################################

provider "aws" {
  alias      = "fusionary-development"
  region     = "us-east-1"
  access_key = var.secrets_manager_access_key_id
  secret_key = var.secrets_manager_secret_key
}

data "aws_secretsmanager_secret_version" "aws_secretsmanager_secret_version_client_aws_credentials" {
  provider = aws.fusionary-development
  # @todo: Set secret ID for client terraform credentials
  secret_id = null
}

locals {
  client_aws_credentials = jsondecode(
    data.aws_secretsmanager_secret_version.aws_secretsmanager_secret_version_client_aws_credentials.secret_string
  )
}

####################
# Client AWS Account
####################

locals {
  # @todo: Specify default region for client resources
  aws_region = "us-east-2"
}

provider "aws" {
  region     = local.aws_region
  access_key = local.client_aws_credentials.aws_access_key
  secret_key = local.client_aws_credentials.aws_secret_key

  # @todo: Set default tags for all resources
  default_tags {
    tags = {
    }
  }
}

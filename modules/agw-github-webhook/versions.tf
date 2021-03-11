terraform {
  required_version = ">=0.14.8"
  experiments      = [module_variable_optional_attrs]
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.22"
    }
    github = {
      source  = "integrations/github"
      version = ">=4.4.0"
    }
  }
}
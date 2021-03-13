variable "api_name" {
  description = "Name of API-Gateway"
  type        = string
  default     = "custom-github-webhook"
}

variable "api_description" {
  description = "Description for API-Gateway"
  type        = string
  default     = "API used for custom GitHub webhooks"
}

variable "named_repos" {
  description = "List of GitHub repositories to create webhooks for"
  type = list(object({
    name   = string
    events = list(string)
    active = optional(bool)
  }))
  default = []
}

variable "queried_repos" {
  description = "List of queries to match repositories used for creating github webhooks. See for query syntax: https://docs.github.com/en/github/searching-for-information-on-github/understanding-the-search-syntax"
  type = list(object({
    query  = string
    events = list(string)
    active = optional(bool)
  }))
  default = []
}

variable "create_github_secret_ssm_param" {
  description = "Determines if module should provision AWS SSM parameter for Github secret"
  type = bool
  default = false
}

variable "github_secret_ssm_key" {
  description = "Key for github secret within AWS SSM Parameter Store"
  type        = string
  default     = "github-webhook-secret"
}

variable "github_secret_ssm_description" {
  description = "Github secret SSM parameter description"
  type        = string
  default     = "Secret value for Github Webhooks"
}

variable "github_secret_ssm_value" {
  description = "Sensitive value for github webhook secret. If not provided, module looks for pre-existing SSM parameter via `github_secret_ssm_key`"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_secret_ssm_tags" {
  description = "Tags for Github webhook secret SSM parameter"
  type        = map(string)
  default     = {}
}

variable "child_function_arn" {
  description = "Downstream Lambda function ARN to be invoked"
  type        = string
  default     = null
}

variable "function_name" {
  description = "Name of Lambda function"
  type        = string
  default     = "payload-validator"
}
variable "api_name" {
  description = "Name of API-Gateway"
  type        = string
  default     = null
}

variable "api_description" {
  description = "Description for API-Gateway"
  type        = string
  default     = "API used for custom GitHub webhooks"
}

variable "async_lambda_invocation" {
  description = <<EOF
Determines if the backend Lambda function for the API Gateway is invoked asynchronously.
If true, the API Gateway REST API method will not return the Lambda results to the client.
See for more info: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-integration-async.html
  EOF
  type = bool
  default = false
}

variable "repos" {
  description = "List of GitHub repositories to create webhooks for"
  type = list(object({
    name   = string
    events = list(string)
  }))
  default = []
}

variable "create_github_secret_ssm_param" {
  description = "Determines if module should provision AWS SSM parameter for Github secret"
  type        = bool
  default     = false
}

variable "github_secret_ssm_key" {
  description = "Key for github secret within AWS SSM Parameter Store"
  type        = string
  default     = null
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

variable "lambda_success_destination_arns" {
  description = "AWS ARNs of services that will be invoked if Lambda function succeeds"
  type        = list(string)
  default     = []
}

variable "lambda_failure_destination_arns" {
  description = "AWS ARNs of services that will be invoked if Lambda function fails"
  type        = list(string)
  default     = []
}

variable "function_name" {
  description = "Name of Lambda function"
  type        = string
  default     = null
}
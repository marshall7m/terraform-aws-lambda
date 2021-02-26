
variable "enabled" {
  description = "Determines if module should active"
  type        = bool
  default     = true
}

variable "filename" {
  description = "Local path to function zip"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = <<EOF
  The base64-encoded SHA256 hash of the package file specified under `filename` or `s3_key`. 
  Used to identify and update source code changes for Lambda function.
  EOF
  type        = string
  default     = null
}

variable "function_name" {
  description = "Name of function to invoke within filename"
  type        = string
}

variable "role_arn" {
  description = "IAM role for Lambda function"
  type        = string
  default     = null
}

variable "handler" {
  description = "Lambda Function entrypoint"
  type        = string
}

variable "runtime" {
  description = "Runtime for Lambda Function (e.g python3.8, go1.x, ruby2.5, etc.)"
  type        = string
}

variable "env_vars" {
  description = "Environment variables to pass into Lambda Function"
  type        = map(string)
  default     = {}
}

variable "custom_role_policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "statements" {
  description = "IAM policy statements for role permissions"
  type = list(object({
    effect    = string
    resources = list(string)
    actions   = list(string)
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })))
  }))
  default = []
}

variable "allowed_to_invoke_arns" {
  description = "AWS entities that can invoke the lambda function"
  type        = list(string)
  default     = []
}

variable "lambda_layers" {
  description = "List of Lambda layers that will be accessible to the Lambda function"
  type = list(object({
    filename          = optional(string)
    name              = string
    runtimes          = list(string)
    description       = optional(string)
    source_code_hash  = optional(string)
    license_info      = optional(string)
    s3_bucket         = optional(string)
    s3_key            = optional(string)
    s3_object_version = optional(string)
  }))
  default = []
}
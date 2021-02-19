
variable "enabled" {
  description = "Determines if module should active"
  type        = bool
  default     = true
}

variable "filename" {
  description = "Local path to function zip"
  type        = string
}

variable "function_name" {
  description = "Name of function to invoke within filename"
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
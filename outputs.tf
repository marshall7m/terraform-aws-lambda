output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this[0].arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this[0].function_name
}

output "function_invoke_arn" {
  description = "ARN used to invoke the Lambda function via AWS API Gateway"
  value       = aws_lambda_function.this[0].invoke_arn
}

output "role_arn" {
  description = "ARN of the IAM role the Lambda function assumes"
  value       = module.iam_role[0].role_arn
}

output "layer_arns" {
  description = "List of Lambda layer ARNS"
  value       = try(aws_lambda_layer_version.this[*].arn, [])
}

output "cw_log_group_arn" {
  description = "ARN of the CloudWatch log group associated with the Lambda function"
  value       = one([aws_cloudwatch_log_group.this[0].arn])
}

output "cw_log_group_name" {
  description = "Name of the CloudWatch log group associated with the Lambda function"
  value       = one([aws_cloudwatch_log_group.this[0].name])
}
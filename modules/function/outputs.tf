output "function_arn" {
  value = aws_lambda_function.this[0].arn
}

output "function_name" {
  value = var.function_name
}

output "role_arn" {
  value = module.iam_role[0].role_arn
}

output "function_invoke_arn" {
  value = aws_lambda_function.this[0].invoke_arn
}

output "layer_arns" {
  value = try(aws_lambda_layer_version.this[*].arn, [])
}
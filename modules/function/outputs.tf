output "function_arn" {
  value = aws_lambda_function.this[0].arn
}

output "role_arn" {
  value = module.iam_role[0].role_arn
}
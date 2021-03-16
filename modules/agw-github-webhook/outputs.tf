output "repos" {
  value = local.all_repos_final
}

output "invoke_url" {
  description = "API invoke URL the github webhook will ping"
  value       = "${aws_api_gateway_deployment.this.invoke_url}${aws_api_gateway_stage.this.stage_name}${aws_api_gateway_resource.this.path}"
}

output "function_name" {
  description = "Name of AWS Lambda function used to validate Github webhook"
  value       = local.function_name
}
output "repos" {
  value = local.all_repos_final
}

output "invoke_url" {
  value = "${aws_api_gateway_deployment.this.invoke_url}${aws_api_gateway_stage.this.stage_name}${aws_api_gateway_resource.this.path}"
}
locals {
  repos = [for repo in var.repos : defaults(repo, {
    active = true
  })]
  repo_queries = [for group in var.repo_queries : merge(group, { query = "${group.query} user:${data.github_user.current.login}" }) if length(regexall("user:\\s.+", group.query)) == 0]
  query_final = distinct(flatten([for i in range(length(local.repo_queries)) :
    values({ for repo in data.github_repositories.queried[i].names :
      repo => merge({ name = repo }, local.repo_queries[i])
    if contains(local.repos[*].name, repo) == false })
  ]))
  all_repos = concat(local.repos, local.query_final)
}

resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = var.api_description
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_method.this, aws_api_gateway_integration.this]
}

# resource "aws_api_gateway_method_settings" "all" {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   stage_name  = aws_api_gateway_stage.this.stage_name
#   method_path = "*/*"

#   settings {
#     metrics_enabled = true
#     logging_level   = "INFO"
#   }
# }

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "prod"
}

resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "incoming"
}

resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this.id
  http_method             = aws_api_gateway_method.this.http_method
  type                    = "AWS_PROXY"
  uri                     = module.lambda.function_invoke_arn
  integration_http_method = "POST"
  #   request_templates = {
  #     "application/json" = <<EOF
  # {
  #    "body" : $input.json('$')
  # }
  # EOF
}

module "lambda" {
  source           = "../function"
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  function_name    = "github-webhook-incoming"
  handler          = "lambda_handler"
  runtime          = "python3.8"
  allowed_to_invoke = [
    {
      statement_id = "test"
      principal    = "apigateway.amazonaws.com"
      arn          = aws_api_gateway_rest_api.this.execution_arn
    }
  ]
  enable_cw_logs = true
  env_vars = {
    github_token = var.github_token
    path_filter  = var.path_filter
  }
  lambda_layers = [
    {
      name             = "lambda-deps"
      filename         = data.archive_file.lambda_deps.output_path
      source_code_hash = data.archive_file.lambda_deps.output_base64sha256
      runtimes         = ["python3.8"]
    }
  ]
}

data "archive_file" "lambda_deps" {
  type        = "zip"
  source_dir  = "${path.module}/package/python"
  output_path = "${path.module}/package.zip"
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/function.zip"
}

resource "null_resource" "pip_deps" {
  triggers = {
    zip_hash = fileexists("${path.module}/package.zip") ? data.archive_file.lambda_deps.output_base64sha256 : timestamp()
  }
  provisioner "local-exec" {
    command = <<EOF
    pip install --target ${path.module}/package/python -r ${path.module}/package/requirements.txt
    EOF
  }
}
resource "github_repository_webhook" "this" {
  for_each   = { for repo in local.all_repos : repo.name => repo }
  repository = each.value.name

  configuration {
    url          = "${aws_api_gateway_deployment.this.invoke_url}${aws_api_gateway_stage.this.stage_name}${aws_api_gateway_resource.this.path}"
    content_type = "json"
    insecure_ssl = false
  }

  active = each.value.active

  events = each.value.events
}

data "github_repository" "this" {
  for_each = { for repo in local.all_repos : repo.name => repo }
  name     = each.value.name
}

data "github_repositories" "queried" {
  count = length(local.repo_queries)
  query = local.repo_queries[count.index].query
}

data "github_user" "current" {
  username = ""
}


resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = module.cw_role.role_arn
}

module "cw_role" {
  source                  = "github.com/marshall7m/terraform-aws-iam/modules//iam-role"
  role_name               = "Account-API-Gateway-CloudWatch"
  trusted_services        = ["apigateway.amazonaws.com"]
  custom_role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"]
}
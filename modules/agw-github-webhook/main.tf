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

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "prod"
}

resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "github"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda.function_invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_api_gateway_resource.this,
    aws_api_gateway_method.proxy_root,
    aws_api_gateway_integration.lambda_root
  ]
}

module "lambda" {
  source           = "../function"
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  function_name    = var.function_name
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  allowed_to_invoke = [
    {
      statement_id = "APIGatewayInvokeAccess"
      principal    = "apigateway.amazonaws.com"
      arn          = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
    }
  ]
  enable_cw_logs = true
  env_vars = {
    CHILD_LAMBDA_ARN              = var.child_function_arn
    GITHUB_WEBHOOK_SECRET_SSM_KEY = var.github_secret_ssm_key
  }
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    aws_iam_policy.lambda.arn
  ]
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid    = "GithubWebhookSecretReadAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [try(aws_ssm_parameter.github_secret[0].arn, data.aws_ssm_parameter.github_secret[0].arn)]
  }
  dynamic "statement" {
    for_each = var.child_function_arn != null ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "lambda:InvokeFunction",
        "lambnda:InvokeAsync"
      ]
      resources = [var.child_function_arn]
    }
  }
}

resource "aws_iam_policy" "lambda" {
  name   = var.function_name
  policy = data.aws_iam_policy_document.lambda.json
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/function.zip"
}

resource "github_repository_webhook" "this" {
  for_each   = { for repo in local.all_repos : repo.name => repo }
  repository = each.value.name

  configuration {
    url          = "${aws_api_gateway_deployment.this.invoke_url}${aws_api_gateway_stage.this.stage_name}${aws_api_gateway_resource.this.path}"
    content_type = "json"
    insecure_ssl = false
    secret       = var.github_secret_ssm_value != "" ? var.github_secret_ssm_value : data.aws_ssm_parameter.github_secret[0].value
  }

  active = each.value.active
  events = each.value.events
}

resource "aws_ssm_parameter" "github_secret" {
  count       = var.github_secret_ssm_value != "" ? 1 : 0
  name        = var.github_secret_ssm_key
  description = var.github_secret_ssm_description
  type        = "SecureString"
  value       = var.github_secret_ssm_value
  tags        = var.github_secret_ssm_tags
}

data "aws_ssm_parameter" "github_secret" {
  count = var.github_secret_ssm_value == "" ? 1 : 0
  name  = var.github_secret_ssm_key
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
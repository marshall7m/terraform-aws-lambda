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
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = "prod"
}

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

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this.id
  http_method             = aws_api_gateway_method.this.http_method
  type                    = "AWS_PROXY"
  uri                     = module.lambda.function_invoke_arn
  integration_http_method = "POST"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda.zip"
  source_dir  = "lambda/"
}

module "lambda" {
  source                 = "../function"
  filename               = data.archive_file.lambda_zip.output_path
  function_name          = "github-webhook-incoming"
  handler                = "lambda_handler"
  runtime                = "python3.8"
  allowed_to_invoke_arns = [aws_api_gateway_rest_api.this.arn]
}

resource "github_repository_webhook" "this" {
  for_each   = { for repo in local.all_repos : repo.name => repo }
  repository = each.value.name

  configuration {
    url          = data.github_repository.this[each.value.name].http_clone_url
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

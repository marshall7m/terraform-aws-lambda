# TODO: Create option to upload lambda artifacts to s3 given s3 better supprot with bigger files

locals {
  allowed_to_invoke_arns = [for arn in var.allowed_to_invoke_arns : {
    service    = split(":", arn)[2]
    source_arn = arn
  }]
}

resource "aws_lambda_function" "this" {
  count            = var.enabled ? 1 : 0
  filename         = var.filename
  function_name    = var.function_name
  role             = coalesce(var.role_arn, module.iam_role[0].role_arn)
  handler          = var.handler
  source_code_hash = filebase64sha256(var.filename)
  runtime          = var.runtime
  layers           = aws_lambda_layer_version.this[*].arn

  environment {
    variables = var.env_vars
  }
}

resource "aws_lambda_permission" "this" {
  count         = var.enabled ? length(local.allowed_to_invoke_arns) : 0
  statement_id  = "AllowInvokeFrom${title(local.allowed_to_invoke_arns[count.index].service)}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].function_name
  principal     = "${local.allowed_to_invoke_arns[count.index].service}.amazonaws.com"
  source_arn    = local.allowed_to_invoke_arns[count.index].source_arn
}

module "iam_role" {
  count                   = var.enabled ? 1 : 0
  source                  = "github.com/marshall7m/terraform-aws-iam/modules//iam-role"
  role_name               = var.function_name
  trusted_services        = ["lambda.amazonaws.com"]
  custom_role_policy_arns = length(var.statements) == 0 && length(var.custom_role_policy_arns) == 0 ? ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"] : var.custom_role_policy_arns
  statements              = var.statements
}

resource "aws_lambda_layer_version" "this" {
  for_each            = { for layer in var.lambda_layers : layer.name => layer }
  filename            = each.value.filename
  layer_name          = each.value.name
  compatible_runtimes = each.value.runtimes
  source_code_hash    = filebase64sha256(var.filename)
  description         = each.value.description
  license_info        = each.value.license_info
  s3_bucket           = each.value.s3_bucket
  s3_key              = each.value.s3_key
  s3_object_version   = each.value.s3_object_version
}
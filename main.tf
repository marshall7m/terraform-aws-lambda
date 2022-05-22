# TODO: Create option to upload lambda artifacts to s3 given s3 better support with bigger files
# TODO: Add other function sources e.g. S3, ECR img, etc.

locals {
  allowed_to_invoke = [for entity in var.allowed_to_invoke : merge(entity,
  { statement_id = "AllowInvokeFrom${title(split(".", entity.principal)[0])}" })]
}

resource "aws_lambda_function" "this" {
  count            = var.enabled ? 1 : 0
  filename         = var.filename
  image_uri        = var.image_uri
  timeout          = var.timeout
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  function_name    = var.function_name
  role             = coalesce(var.role_arn, module.iam_role[0].role_arn)
  handler          = var.handler
  source_code_hash = var.source_code_hash != null ? var.source_code_hash : filebase64sha256(var.filename)
  runtime          = var.runtime
  layers           = [for n in var.lambda_layers[*].name : aws_lambda_layer_version.this[n].arn]

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [1] : []
    content {
      subnet_ids         = var.vpc_config.subnet_ids
      security_group_ids = var.vpc_config.security_group_ids
    }
  }

  dynamic "environment" {
    for_each = var.env_vars != {} ? [1] : []
    content {
      variables = var.env_vars
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.this
  ]
}

resource "aws_lambda_permission" "this" {
  count         = var.enabled ? length(local.allowed_to_invoke) : 0
  statement_id  = local.allowed_to_invoke[count.index].statement_id
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].function_name
  principal     = local.allowed_to_invoke[count.index].principal
  source_arn    = local.allowed_to_invoke[count.index].arn
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "vpc_access" {
  count = var.vpc_config != null ? 1 : 0
  statement {
    sid    = "VPCAcess"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterfacePermission"
    ]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:network-interface/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "ec2:Subnet"
      values   = [for subnet in var.vpc_config.subnet_ids : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:subnet/${subnet}"]
    }
  }
}

resource "aws_iam_policy" "vpc_access" {
  count       = var.vpc_config != null ? 1 : 0
  name        = "${var.function_name}-vpc-access"
  description = "Allows Lambda function to create VPC resources neccessary for function to be associated with VPC"
  policy      = data.aws_iam_policy_document.vpc_access[0].json
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = var.vpc_config != null ? 1 : 0
  role       = module.iam_role[0].role_name
  policy_arn = aws_iam_policy.vpc_access[0].arn
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = length(var.statements) == 0 && length(var.custom_role_policy_arns) == 0 ? 1 : 0
  role       = module.iam_role[0].role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "iam_role" {
  count                      = var.enabled ? 1 : 0
  source                     = "github.com/marshall7m/terraform-aws-iam/modules//iam-role"
  role_name                  = var.function_name
  trusted_services           = ["lambda.amazonaws.com"]
  custom_role_policy_arns    = var.custom_role_policy_arns
  statements                 = var.statements
  role_force_detach_policies = var.force_detach_policies
}

resource "aws_lambda_layer_version" "this" {
  for_each            = { for layer in var.lambda_layers : layer.name => layer }
  filename            = each.value.filename
  layer_name          = each.value.name
  compatible_runtimes = each.value.runtimes
  source_code_hash    = each.value.source_code_hash != null ? each.value.source_code_hash : filebase64sha256(each.value.filename)
  description         = each.value.description
  license_info        = each.value.license_info
  s3_bucket           = each.value.s3_bucket
  s3_key              = each.value.s3_key
  s3_object_version   = each.value.s3_object_version
}

resource "aws_cloudwatch_log_group" "this" {
  count             = var.enable_cw_logs ? 1 : 0
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.cw_retention_in_days
}
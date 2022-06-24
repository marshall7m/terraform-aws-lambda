# Terraform AWS Lambda

## Description

Terraform Module that provisions AWS resources to host a Lambda Function

## Features

- If `var.statements` and `var.custom_role_policy_arns` are not defined, an `AWSLambdaBasicExecutionRole` policy is attached to the Lambda Function's IAM role
- If `var.vpc_config` is defined, a policy that allows the Lambda Function to be hosted within the VPC's subnet(s) is attached to the Lambda Function's IAM role

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.38 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.38 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_role"></a> [iam\_role](#module\_iam\_role) | github.com/marshall7m/terraform-aws-iam//modules/iam-role | v0.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.destinations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.vpc_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.destinations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vpc_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function_event_invoke_config.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_event_invoke_config) | resource |
| [aws_lambda_layer_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [aws_lambda_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.destinations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_to_invoke"></a> [allowed\_to\_invoke](#input\_allowed\_to\_invoke) | Services that are allowed to invoke the Lambda function | <pre>list(object({<br>    statement_id = optional(string)<br>    principal    = string<br>    arn          = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_custom_role_policy_arns"></a> [custom\_role\_policy\_arns](#input\_custom\_role\_policy\_arns) | List of IAM policy ARNs to attach to the role | `list(string)` | `[]` | no |
| <a name="input_cw_retention_in_days"></a> [cw\_retention\_in\_days](#input\_cw\_retention\_in\_days) | Number of days Cloudwatch should retain a log event | `number` | `14` | no |
| <a name="input_destination_config"></a> [destination\_config](#input\_destination\_config) | AWS ARNs of services that will be invoked if Lambda function succeeds or fails | <pre>list(object({<br>    success = optional(string)<br>    failure = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_enable_cw_logs"></a> [enable\_cw\_logs](#input\_enable\_cw\_logs) | Determines if Cloudwatch log group should be created and associated with Lambda function | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Determines if module should active | `bool` | `true` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | Environment variables to pass into Lambda Function | `map(string)` | `{}` | no |
| <a name="input_filename"></a> [filename](#input\_filename) | Local path to function zip | `string` | `null` | no |
| <a name="input_force_detach_policies"></a> [force\_detach\_policies](#input\_force\_detach\_policies) | Determines if policies attached to the Lambda Function's IAM role should be forcefully detached if the role is destroyed | `bool` | `false` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name of function to invoke within filename | `string` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | Lambda Function entrypoint | `string` | n/a | yes |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | AWS ECR image URI that contains the Lambda function deployment package | `string` | `null` | no |
| <a name="input_lambda_layers"></a> [lambda\_layers](#input\_lambda\_layers) | List of Lambda layers that will be created and accessible to the Lambda function.<br>A maximum of 5 Lambda layers can be attached between var.lambda\_layers and var.layer\_arns. | <pre>list(object({<br>    filename          = optional(string)<br>    name              = string<br>    runtimes          = list(string)<br>    description       = optional(string)<br>    source_code_hash  = optional(string)<br>    license_info      = optional(string)<br>    s3_bucket         = optional(string)<br>    s3_key            = optional(string)<br>    s3_object_version = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_layer_arns"></a> [layer\_arns](#input\_layer\_arns) | Lambda layer ARNs to attach to the Lambda Function. <br>A maximum of 5 Lambda layers can be attached between var.lambda\_layers and var.layer\_arns. | `list(string)` | `[]` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | IAM role for Lambda function | `string` | `null` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Runtime for Lambda Function (e.g python3.8, go1.x, ruby2.5, etc.) | `string` | n/a | yes |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | AWS S3 bucket that contains the Lambda function deployment package | `string` | `null` | no |
| <a name="input_s3_key"></a> [s3\_key](#input\_s3\_key) | AWS S3 bucket key of the Lambda function deployment package | `string` | `null` | no |
| <a name="input_source_code_hash"></a> [source\_code\_hash](#input\_source\_code\_hash) | The base64-encoded SHA256 hash of the package file specified under `filename` or `s3_key`. <br>  Used to identify and update source code changes for Lambda function. | `string` | `null` | no |
| <a name="input_statements"></a> [statements](#input\_statements) | IAM policy statements for role permissions | <pre>list(object({<br>    effect    = string<br>    resources = list(string)<br>    actions   = list(string)<br>    conditions = optional(list(object({<br>      test     = string<br>      variable = string<br>      values   = list(string)<br>    })))<br>  }))</pre> | `[]` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Time in seconds the Lambda function has to run | `number` | `3` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Subnet and security group IDs to associate the Lambda function with | <pre>object({<br>    subnet_ids         = list(string)<br>    security_group_ids = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cw_log_group_arn"></a> [cw\_log\_group\_arn](#output\_cw\_log\_group\_arn) | ARN of the CloudWatch log group associated with the Lambda function |
| <a name="output_cw_log_group_name"></a> [cw\_log\_group\_name](#output\_cw\_log\_group\_name) | Name of the CloudWatch log group associated with the Lambda function |
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | ARN of the Lambda function |
| <a name="output_function_invoke_arn"></a> [function\_invoke\_arn](#output\_function\_invoke\_arn) | ARN used to invoke the Lambda function via AWS API Gateway |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Name of the Lambda function |
| <a name="output_layer_arns"></a> [layer\_arns](#output\_layer\_arns) | List of Lambda layer ARNS |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role the Lambda function assumes |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
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
| terraform | >= 0.15.0 |
| aws | >= 3.38 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.38 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allowed\_to\_invoke | Services that are allowed to invoke the Lambda function | <pre>list(object({<br>    statement_id = optional(string)<br>    principal    = string<br>    arn          = optional(string)<br>  }))</pre> | `[]` | no |
| custom\_role\_policy\_arns | List of IAM policy ARNs to attach to the role | `list(string)` | `[]` | no |
| cw\_retention\_in\_days | Number of days Cloudwatch should retain a log event | `number` | `14` | no |
| enable\_cw\_logs | Determines if Cloudwatch log group should be created and associated with Lambda function | `bool` | `true` | no |
| enabled | Determines if module should active | `bool` | `true` | no |
| env\_vars | Environment variables to pass into Lambda Function | `map(string)` | `{}` | no |
| filename | Local path to function zip | `string` | `null` | no |
| force\_detach\_policies | Determines if policies attached to the Lambda Function's IAM role should be forcefully detached if the role is destroyed | `bool` | `false` | no |
| function\_name | Name of function to invoke within filename | `string` | n/a | yes |
| handler | Lambda Function entrypoint | `string` | n/a | yes |
| image\_uri | AWS ECR image URI that contains the Lambda function deployment package | `string` | `null` | no |
| lambda\_layers | List of Lambda layers that will be accessible to the Lambda function | <pre>list(object({<br>    filename          = optional(string)<br>    name              = string<br>    runtimes          = list(string)<br>    description       = optional(string)<br>    source_code_hash  = optional(string)<br>    license_info      = optional(string)<br>    s3_bucket         = optional(string)<br>    s3_key            = optional(string)<br>    s3_object_version = optional(string)<br>  }))</pre> | `[]` | no |
| role\_arn | IAM role for Lambda function | `string` | `null` | no |
| runtime | Runtime for Lambda Function (e.g python3.8, go1.x, ruby2.5, etc.) | `string` | n/a | yes |
| s3\_bucket | AWS S3 bucket that contains the Lambda function deployment package | `string` | `null` | no |
| s3\_key | AWS S3 bucket key of the Lambda function deployment package | `string` | `null` | no |
| source\_code\_hash | The base64-encoded SHA256 hash of the package file specified under `filename` or `s3_key`. <br>  Used to identify and update source code changes for Lambda function. | `string` | `null` | no |
| statements | IAM policy statements for role permissions | <pre>list(object({<br>    effect    = string<br>    resources = list(string)<br>    actions   = list(string)<br>    conditions = optional(list(object({<br>      test     = string<br>      variable = string<br>      values   = list(string)<br>    })))<br>  }))</pre> | `[]` | no |
| timeout | Time in seconds the Lambda function has to run | `number` | `3` | no |
| vpc\_config | Subnet and security group IDs to associate the Lambda function with | <pre>object({<br>    subnet_ids         = list(string)<br>    security_group_ids = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| cw\_log\_group\_arn | ARN of the CloudWatch log group associated with the Lambda function |
| cw\_log\_group\_name | Name of the CloudWatch log group associated with the Lambda function |
| function\_arn | ARN of the Lambda function |
| function\_invoke\_arn | ARN used to invoke the Lambda function via AWS API Gateway |
| function\_name | Name of the Lambda function |
| layer\_arns | List of Lambda layer ARNS |
| role\_arn | ARN of the IAM role the Lambda function assumes |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

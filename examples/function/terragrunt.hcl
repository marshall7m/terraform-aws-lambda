include {
  path = find_in_parent_folders()
}

locals {
  aws_vars   = read_terragrunt_config(find_in_parent_folders("aws.hcl"))
  account_id = local.aws_vars.locals.account_id
}
terraform {
  source = "../../modules//function"
}

inputs = {
  filename      = "foo.zip"
  function_name = "foo"
  handler       = "lambda_handler"
  runtime       = "python3.8"
  env_vars = {
    bar = "foo"
  }
  allowed_to_invoke_arns = ["arn:aws:codepipeline:us-west-2:${local.account_id}:foo-pipeline"]
}

provider "random" {}

resource "random_id" "lambda_function" {
  byte_length = 8
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/function.zip"
}

module "mut_function" {
  source           = "../../..//"
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  function_name    = "mut-terraform-aws-lambda-function-${random_id.lambda_function.id}"
  handler          = "lambda_handler"
  runtime          = "python3.8"
  env_vars = {
    bar = "foo"
  }
}
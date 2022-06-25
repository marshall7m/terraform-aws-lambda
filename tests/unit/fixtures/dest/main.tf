provider "random" {}

resource "random_id" "lambda_function" {
  byte_length = 8
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/../function"
  output_path = "${path.module}/function.zip"
}

resource "aws_sqs_queue" "this" {
  name = "mut-terraform-aws-lambda-function-${random_id.lambda_function.id}"
}

module "mut_function" {
  source           = "../../../..//"
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  function_name    = "mut-terraform-aws-lambda-function-${random_id.lambda_function.id}"
  handler          = "lambda_handler"
  runtime          = "python3.8"
  env_vars = {
    bar = "foo"
  }

  destination_config = {
    # ensures that the module is able to handle arns that haven't been created yet 
    success = aws_sqs_queue.this.arn
    failure = "arn:aws:lambda:us-west-2:000000000000:function:failure"
  }
}
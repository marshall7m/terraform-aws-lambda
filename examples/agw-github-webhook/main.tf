terraform {
  required_version = "0.14.8"
  required_providers {
    testing = {
      source  = "apparentlymart/testing"
      version = "0.0.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "random" {}

resource "random_password" "this" {
  length = 20
}

resource "github_repository" "test" {
  name        = "foo"
  description = "Test repo for mut: agw-github-webhook"
  auto_init   = true
  visibility  = "public"
}

resource "github_repository_file" "test" {
  repository          = github_repository.test.name
  branch              = "master"
  file                = "test.txt"
  content             = "used to trigger repo's webhook for testing associated mut: agw-github-webhook"
  commit_message      = "test file"
  overwrite_on_create = true
  depends_on = [
    module.mut_agw_github_webhook
  ]
}

module "mut_agw_github_webhook" {
  source = "../../modules/agw-github-webhook"
  named_repos = [
    {
      name   = github_repository.test.name
      events = ["push"]
    }
  ]
  create_github_secret_ssm_param = true
  github_secret_ssm_value        = random_password.this.result
  depends_on = [
    github_repository.test
  ]
}

data "aws_lambda_invocation" "not_sha_signed" {
  function_name = module.mut_agw_github_webhook.function_name

  input = jsonencode(
    {
      "headers" = {
        "X-Hub-Signature-256" = sha256("test")
      }
      "body" = {}
    }
  )
}

data "aws_lambda_invocation" "invalid_sig" {
  function_name = module.mut_agw_github_webhook.function_name

  input = jsonencode(
    {
      "headers" = {
        "X-Hub-Signature-256" = "sha256=${sha256("test")}"
      }
      "body" = <<EOF
      {
        "test" = "foo"
      }
      EOF
    }
  )
}

data "aws_lambda_invocation" "valid_sig" {
  function_name = module.mut_agw_github_webhook.function_name

  input = jsonencode(
    {
      "headers" = {
        "X-Hub-Signature-256" = "sha256=${sha256(random_password.this.result)}"
      }
      "body" = <<EOF
      {
        "test" = "foo"
      }
      EOF
    }
  )
}

data "testing_assertions" "sha_sig" {
  subject = "Test lambda signature validation"
  equal "not_sha_signed" {
    statement = "Test invalid signature not signed with sha256"

    got = { for key, value in jsondecode(data.aws_lambda_invocation.not_sha_signed.result) : key => jsondecode(value) }
    want = {
      "statusCode" = 403,
    "body" = { "error" = "signature is invalid" } }
  }

  equal "invalid_sig" {
    statement = "test invalid signature signed with sha256"

    got = { for key, value in jsondecode(data.aws_lambda_invocation.invalid_sig.result) : key => jsondecode(value) }
    want = {
      "statusCode" = 403,
    "body" = { "error" = "signature is invalid" } }
  }
  # TODO: assertion should be true
  equal "valid_sig" {
    statement = "test valid signature signed with sha256"

    got = { for key, value in jsondecode(data.aws_lambda_invocation.valid_sig.result) : key => jsondecode(value) }
    want = {
      "statusCode" = 200,
    "body" = "Request is valid" }
  }
}
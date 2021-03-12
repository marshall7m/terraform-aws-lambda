include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules//agw-github-webhook"
}

inputs = {
  queried_repos = [
    {
      query  = "aws in:name"
      events = ["pull_request"]
    }
  ]
  named_repos = [
    {
      name   = "foo"
      events = ["push"]
    }
  ]
  github_secret_ssm_value = get_env("GITHUB_SECRET")
}
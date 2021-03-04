include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules//agw-github-webhook"
}

inputs = {
  repo_queries = [
    {
      query  = "foo in:name"
      events = ["pull_request"]
    }
  ]
  github_secret_ssm_value = get_env("GITHUB_SECRET")
}
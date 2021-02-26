include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules//agw-github-webhook"
}

inputs = {
  repo_queries = [
    {
      query  = "terraform-aws-codepipeline in:name"
      events = ["pull_request"]
    }
  ]
  github_token = get_env("GITHUB_TOKEN")
  path_filter  = ".+\\.tf$|.+\\.hcl$"
}
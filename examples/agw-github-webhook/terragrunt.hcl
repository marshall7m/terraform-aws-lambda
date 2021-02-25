include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules//agw-github-webhook"
}

inputs = {
  repos = [
    {
      name   = "terraform-aws-codepipeline"
      events = ["push"]
    }
  ]
  repo_queries = [
    {
      query  = "terraform-aws- in:name"
      events = ["push"]
    }
  ]
}
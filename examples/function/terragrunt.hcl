include {
    path = find_in_parent_folders("aws.hcl")
}

terraform {
    source = "../../modules//function"
}

inputs = {
    filename = "foo.zip"
    function_name = "foo"
    handler = "lambda_handler"
    runtime = "python3.8"
    env_vars = {
        bar = "foo"
    }
}
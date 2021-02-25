variable "api_name" {
  description = "Name of API-Gateway"
  type        = string
  default     = "custom-github-webhook"
}

variable "api_description" {
  description = "Description for API-Gateway"
  type        = string
  default     = "API used for custom GitHub webhooks"
}

variable "repos" {
  description = "List of GitHub repositories to create webhooks for"
  type = list(object({
    name   = string
    events = list(string)
    active = optional(bool)
  }))
  default = []
}

variable "repo_queries" {
  description = "List of queries used to match repositories used for creating github webhooks. See for query syntax: https://docs.github.com/en/github/searching-for-information-on-github/understanding-the-search-syntax"
  type = list(object({
    query  = string
    events = list(string)
    active = optional(bool)
  }))
  default = []
}
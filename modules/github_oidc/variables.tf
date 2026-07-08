variable "name_prefix" {
  type = string
}

variable "create_oidc_provider" {
  description = "Set to false if a token.actions.githubusercontent.com OIDC provider already exists in this AWS account (only one is allowed per account)."
  type        = bool
  default     = true
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "allowed_branch" {
  type    = string
  default = "main"
}

variable "ecr_repository_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

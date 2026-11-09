variable "aws_region" {
  description = "AWS region where the ECS stack runs"
  type        = string
  default     = "eu-west-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile used for credentials"
  type        = string
  default     = "vscode"
}

variable "project_name" {
  description = "Must match project_name in ../terraform. It decides the ECR, ECS and IAM role names the deploy role may use."
  type        = string
  default     = "simple-crud-api"
}

variable "github_owner" {
  description = "GitHub user or organisation that owns the repository"
  type        = string
  default     = "Bla-vk"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "Simple-CRUD-API"
}

variable "github_branch" {
  description = "Only workflow runs on this branch can assume the deploy role"
  type        = string
  default     = "main"
}

variable "create_oidc_provider" {
  description = "An AWS account can only have one GitHub OIDC provider. Set to false if it already exists and this stack should look it up instead of creating it."
  type        = bool
  default     = true
}

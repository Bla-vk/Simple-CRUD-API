output "role_arn" {
  description = "Save this as the GitHub repository secret AWS_ROLE_ARN"
  value       = aws_iam_role.deploy.arn
}

output "trusted_subject" {
  description = "The only GitHub token subject allowed to assume the role"
  value       = local.github_sub
}

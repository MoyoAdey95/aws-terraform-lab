output "github_deploy_role_arn" {
  description = "ARN of the role GitHub Actions assumes."
  value       = aws_iam_role.github_deploy.arn
}

output "repository_url" {
  description = "URL of the repository, used as the image name when tagging and pushing."
  value       = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  description = "ARN of the repository, used to scope IAM permissions to it."
  value       = aws_ecr_repository.app.arn
}

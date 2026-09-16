variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "github_sub_prefix" {
  description = "Start of the OIDC sub claim GitHub issues for the repository, before :ref:..."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the repository CI pushes the app image to."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster CI deploys to."
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service CI deploys."
  type        = string
}

variable "execution_role_arn" {
  description = "Task execution role CI may pass to ECS in new task definitions."
  type        = string
}

variable "task_role_arn" {
  description = "Task role CI may pass to ECS in new task definitions."
  type        = string
}

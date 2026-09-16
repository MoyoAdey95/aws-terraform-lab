variable "name_prefix" {
  description = "Prefix for role names."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the repository the execution role may pull from."
  type        = string
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group the execution role may write to."
  type        = string
}

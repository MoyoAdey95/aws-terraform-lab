variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group for container logs."
  type        = string
}

variable "log_retention_days" {
  description = "Days to keep container logs."
  type        = number
  default     = 1
}

variable "image" {
  description = "Full image reference, repository URL and tag."
  type        = string
}

variable "cpu" {
  description = "Task CPU units. 256 is a quarter of a vCPU, the smallest Fargate size."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB. 512 is the smallest size allowed with 256 CPU."
  type        = number
  default     = 512
}

variable "app_port" {
  description = "Port the application container listens on."
  type        = number
}

variable "execution_role_arn" {
  description = "ARN of the role ECS uses to pull the image and write logs."
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the role the application runs as."
  type        = string
}

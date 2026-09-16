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

variable "desired_count" {
  description = "Number of tasks the service keeps running."
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Subnets the tasks run in."
  type        = list(string)
}

variable "tasks_security_group_id" {
  description = "Security group attached to each task."
  type        = string
}

variable "target_group_arn" {
  description = "Target group the service registers tasks in."
  type        = string
}

variable "app_message_secret_arn" {
  description = "ARN of the Secrets Manager secret injected as APP_MESSAGE."
  type        = string
}

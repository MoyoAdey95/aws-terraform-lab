output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.network.public_subnet_ids
}

output "alb_security_group_id" {
  description = "ID of the load balancer security group."
  value       = module.network.alb_security_group_id
}

output "tasks_security_group_id" {
  description = "ID of the ECS tasks security group."
  value       = module.network.tasks_security_group_id
}

output "ecr_repository_url" {
  description = "URL of the app image repository."
  value       = module.ecr.repository_url
}

output "execution_role_arn" {
  description = "ARN of the task execution role."
  value       = module.iam.execution_role_arn
}

output "task_role_arn" {
  description = "ARN of the task role."
  value       = module.iam.task_role_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = module.ecs.cluster_name
}

output "task_definition_arn" {
  description = "ARN of the current task definition revision."
  value       = module.ecs.task_definition_arn
}

output "alb_dns_name" {
  description = "Public DNS name of the load balancer."
  value       = module.alb.dns_name
}

output "ecs_service_name" {
  description = "Name of the ECS service."
  value       = module.ecs.service_name
}

output "alarm_name" {
  description = "Name of the no healthy targets alarm."
  value       = module.monitoring.alarm_name
}

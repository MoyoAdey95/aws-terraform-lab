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

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [for s in aws_subnet.public : s.id]
}

output "alb_security_group_id" {
  description = "ID of the load balancer security group."
  value       = aws_security_group.alb.id
}

output "tasks_security_group_id" {
  description = "ID of the ECS tasks security group."
  value       = aws_security_group.tasks.id
}

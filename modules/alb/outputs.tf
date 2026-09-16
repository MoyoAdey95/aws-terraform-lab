output "dns_name" {
  description = "Public DNS name of the load balancer."
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group the ECS service registers tasks in."
  value       = aws_lb_target_group.app.arn
}

output "alb_arn_suffix" {
  description = "Load balancer ARN suffix, the form CloudWatch metrics use."
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix, the form CloudWatch metrics use."
  value       = aws_lb_target_group.app.arn_suffix
}

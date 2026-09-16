variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives alarm notifications."
  type        = string
  sensitive   = true
}

variable "alb_arn_suffix" {
  description = "Load balancer ARN suffix, as used in CloudWatch metric dimensions."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix, as used in CloudWatch metric dimensions."
  type        = string
}

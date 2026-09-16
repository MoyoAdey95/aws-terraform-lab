variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC the target group belongs to."
  type        = string
}

variable "subnet_ids" {
  description = "Public subnets for the load balancer, in at least two availability zones."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group attached to the load balancer."
  type        = string
}

variable "app_port" {
  description = "Port the targets listen on."
  type        = number
}

variable "health_check_path" {
  description = "Path the target group calls to decide whether a task is healthy."
  type        = string
  default     = "/health"
}

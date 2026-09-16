# Two security groups and a locked-down default.
#
# The load balancer accepts HTTP from anywhere and can only talk to the tasks.
# The tasks accept traffic only from the load balancer's security group, by
# group ID rather than by CIDR, so nothing else in the VPC or on the internet
# can reach them even though they sit in public subnets with public IPs.
#
# Rules are separate aws_vpc_security_group_*_rule resources rather than
# inline blocks. The two groups reference each other, and inline rules would
# create a dependency cycle.

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb"
  description = "Load balancer. HTTP in from the internet, app port out to tasks only."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

resource "aws_security_group" "tasks" {
  name        = "${var.name_prefix}-tasks"
  description = "ECS tasks. App port in from the load balancer only, HTTPS out."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-tasks"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb.id
  description                  = "App port to tasks, covers forwarding and health checks"
  referenced_security_group_id = aws_security_group.tasks.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_ingress_rule" "tasks_from_alb" {
  security_group_id            = aws_security_group.tasks.id
  description                  = "App port from the load balancer only"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# Tasks need HTTPS out to pull the image from ECR, fetch the secret and ship
# logs. With no NAT Gateway and no VPC endpoints, those calls leave through
# the internet gateway using the task's public IP.
resource "aws_vpc_security_group_egress_rule" "tasks_https" {
  security_group_id = aws_security_group.tasks.id
  description       = "HTTPS to AWS APIs (ECR, Secrets Manager, CloudWatch Logs)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# Every VPC comes with a default security group that allows all traffic
# between its members and all outbound traffic. Nothing here uses it, so
# managing it with no rules strips those permissions and stops anything
# launched without an explicit group from getting them.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-default-locked"
  }
}

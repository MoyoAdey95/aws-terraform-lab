# Internet-facing application load balancer in front of the ECS tasks.
#
# HTTP only. There is no domain for this lab, so there is no certificate to
# put on an HTTPS listener. That is the first production delta, not an
# oversight.

resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.subnet_ids
  security_groups    = [var.alb_security_group_id]

  # Rejects requests with malformed headers instead of passing them on to the
  # app, which closes off a class of request smuggling tricks.
  drop_invalid_header_fields = true
}

# Fargate tasks get their own network interface and IP, so targets are
# registered by IP rather than by instance.
resource "aws_lb_target_group" "app" {
  name        = "${var.name_prefix}-api"
  target_type = "ip"
  protocol    = "HTTP"
  port        = var.app_port
  vpc_id      = var.vpc_id

  # The default is 300 seconds, which makes every deploy and every destroy
  # wait five minutes for connections that a lab never has.
  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

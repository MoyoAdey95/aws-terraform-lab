# The service keeps the desired number of tasks running from the task
# definition and registers each one in the load balancer's target group.

resource "aws_ecs_service" "app" {
  name             = "${var.name_prefix}-api"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.app.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  # Tasks sit in the public subnets and need a public IP to reach ECR,
  # CloudWatch Logs and, later, Secrets Manager, because there is no NAT
  # Gateway. Inbound traffic is still limited to the load balancer by the
  # tasks security group. See docs/network-decisions.md.
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.tasks_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "api"
    container_port   = var.app_port
  }

  # Gives a new task time to start before failed health checks count
  # against it.
  health_check_grace_period_seconds = 30

  # If a deployment keeps failing, ECS stops retrying and rolls back to the
  # last working task definition instead of starting tasks in a loop.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

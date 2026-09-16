# ECS cluster, log group and task definition. Nothing runs from this file on
# its own. The task definition is a template, and the service that starts
# tasks from it comes in a later commit.

data "aws_region" "current" {}

# A Fargate cluster is only a namespace, with no servers behind it. Container
# Insights stays off because it publishes extra CloudWatch metrics that bill
# per task, which a lab with one task does not need.
resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

# Created here rather than left to the awslogs driver, so it has a retention
# period and Terraform removes it on destroy. A log group the driver creates
# by itself keeps logs forever and survives teardown.
resource "aws_cloudwatch_log_group" "app" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  # Graviton. The image is built natively for arm64 on an Apple Silicon Mac,
  # so it runs here as is. An x86 task would fail to start with
  # exec format error.
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = var.image
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "api"
        }
      }
    }
  ])
}

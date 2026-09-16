# IAM roles for the ECS tasks.
#
# ECS uses two roles, and keeping them apart is the point of this file. The
# execution role is used by the ECS agent before the container starts, to pull
# the image and set up logging. The task role is what the application code
# itself runs as once it is up. On Cloud Run both jobs fall to the one runtime
# service account.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  region        = data.aws_region.current.region
  log_group_arn = "arn:aws:logs:${local.region}:${local.account_id}:log-group:${var.log_group_name}"
}

# Both roles trust the ECS tasks service, limited to this account. The
# conditions stop another account's ECS tasks from assuming the role through
# the service, which AWS calls the confused deputy problem.
data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ecs:${local.region}:${local.account_id}:*"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.name_prefix}-task-execution"
  description        = "Used by ECS to pull the app image and write container logs."
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

# Written out instead of attaching the AWS managed
# AmazonECSTaskExecutionRolePolicy, which allows pulling from every ECR
# repository and writing to every log group in the account. This allows the
# one repository and the one log group. GetAuthorizationToken has no resource
# to scope to, so it is the only action on "*".
data "aws_iam_policy_document" "execution" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PullAppImage"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    sid = "WriteAppLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${local.log_group_arn}:*"]
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "pull-image-and-write-logs"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

# The app calls no AWS APIs, so the task role has no permissions at all. It
# still exists so the task definition names a role explicitly, and anything
# the app needs later gets granted here rather than on the execution role.
resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-task"
  description        = "Runtime identity of the app container. No permissions."
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

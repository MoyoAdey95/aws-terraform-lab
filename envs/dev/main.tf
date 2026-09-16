# Composition root for the dev environment. Modules do the work and this file
# wires them together.

# Named once here because two modules need it. The IAM module scopes log
# permissions to it, and the ECS module creates the log group itself.
locals {
  log_group_name = "/ecs/${var.name_prefix}-api"
}

# The demo secret lives here rather than in a module, as it did in
# gcp-terraform-lab. One secret with no reuse story does not need a module.
#
# recovery_window_in_days = 0 deletes it immediately on destroy. The default
# keeps a deleted secret for 30 days, and its name cannot be reused until then,
# so a destroy followed by a fresh apply would fail.
resource "aws_secretsmanager_secret" "app_message" {
  name                    = "${var.name_prefix}/app-message"
  description             = "Message returned by the demo app, injected as APP_MESSAGE."
  recovery_window_in_days = 0
}

# The value is written by Terraform, so it is stored in the state file. That
# is acceptable here because the state bucket is private and encrypted and the
# value is a demo string. For a real secret the value would be set outside
# Terraform. See docs/production-deltas.md.
resource "aws_secretsmanager_secret_version" "app_message" {
  secret_id     = aws_secretsmanager_secret.app_message.id
  secret_string = var.app_message
}

module "network" {
  source = "../../modules/network"

  name_prefix         = var.name_prefix
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  public_subnet_cidrs = var.public_subnet_cidrs
  app_port            = var.app_port
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix = var.name_prefix
}

module "iam" {
  source = "../../modules/iam"

  name_prefix        = var.name_prefix
  ecr_repository_arn = module.ecr.repository_arn
  log_group_name     = local.log_group_name
  app_secret_arn     = aws_secretsmanager_secret.app_message.arn
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix        = var.name_prefix
  log_group_name     = local.log_group_name
  image              = "${module.ecr.repository_url}:${var.image_tag}"
  app_port           = var.app_port
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn

  app_message_secret_arn = aws_secretsmanager_secret.app_message.arn

  subnet_ids              = module.network.public_subnet_ids
  tasks_security_group_id = module.network.tasks_security_group_id
  target_group_arn        = module.alb.target_group_arn

  # ECS refuses to attach a service to a target group that has no listener
  # yet. This makes a fresh apply create the load balancer side first.
  depends_on = [module.alb]
}

module "alb" {
  source = "../../modules/alb"

  name_prefix           = var.name_prefix
  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.public_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  app_port              = var.app_port
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix             = var.name_prefix
  alert_email             = var.alert_email
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
}

module "ci" {
  source = "../../modules/ci"

  name_prefix        = var.name_prefix
  github_repository  = var.github_repository
  ecr_repository_arn = module.ecr.repository_arn
  cluster_name       = module.ecs.cluster_name
  service_name       = module.ecs.service_name
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
}

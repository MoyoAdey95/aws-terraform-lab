# Composition root for the dev environment. Modules do the work and this file
# wires them together.

# Named once here because two modules need it. The IAM module scopes log
# permissions to it, and the ECS module creates the log group itself.
locals {
  log_group_name = "/ecs/${var.name_prefix}-api"
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
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix        = var.name_prefix
  log_group_name     = local.log_group_name
  image              = "${module.ecr.repository_url}:${var.image_tag}"
  app_port           = var.app_port
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
}

module "alb" {
  source = "../../modules/alb"

  name_prefix           = var.name_prefix
  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.public_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  app_port              = var.app_port
}

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

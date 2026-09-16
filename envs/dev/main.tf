# Composition root for the dev environment. Modules do the work and this file
# wires them together.

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

# VPC for the lab. Two public subnets in two availability zones, because an
# application load balancer will not create with fewer than two.
#
# There is deliberately no NAT Gateway and no private subnet. A NAT Gateway
# bills by the hour whether or not anything uses it, and nothing in this lab
# needs one. The reasoning is in docs/network-decisions.md.

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# map_public_ip_on_launch stays false. A subnet being public only means it
# has a route to the internet gateway. Whether a task gets a public IP is
# decided on the ECS service, so nothing picks one up by accident.
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-public-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

locals {
  public_subnets = zipmap(var.azs, var.public_subnet_cidrs)
}

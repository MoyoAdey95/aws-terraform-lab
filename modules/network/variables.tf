variable "name_prefix" {
  description = "Prefix for network resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones for the public subnets, one subnet per zone."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "An application load balancer needs subnets in at least two availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, in the same order as azs."
  type        = list(string)
}

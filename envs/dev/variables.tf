variable "region" {
  description = "AWS region for all resources in this environment."
  type        = string
  default     = "eu-west-2"
}

variable "profile" {
  description = "Local AWS CLI profile used for authentication."
  type        = string
  default     = "personal"
}

variable "project" {
  description = "Project tag applied to every resource."
  type        = string
  default     = "aws-terraform-lab"
}

variable "env" {
  description = "Environment tag applied to every resource."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag applied to every resource."
  type        = string
  default     = "moyo"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "aws-lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Kept clear of the 10.10.0.0/24 range used in gcp-terraform-lab."
  type        = string
  default     = "10.20.0.0/16"
}

# Zone names are set explicitly rather than read from a data source, so the
# plan always shows where things will go. Checked with
# aws ec2 describe-availability-zones on 16 Sep 2026.
variable "azs" {
  description = "Availability zones for the public subnets."
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, in the same order as azs."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

# Matches the PORT the repo 1 container listens on.
variable "app_port" {
  description = "Port the application container listens on."
  type        = number
  default     = 8080
}

# Tags in the repository are immutable, so this names one exact image. v2 is
# the build with the base image packages upgraded.
variable "image_tag" {
  description = "Tag of the app image in ECR to run."
  type        = string
  default     = "v2"
}

variable "app_message" {
  description = "Value stored in the demo secret and returned by the app."
  type        = string
  sensitive   = true
  default     = "hello from secrets manager"
}

# No default, so no address is committed to a public repo. Set it in the
# shell with TF_VAR_alert_email or in an untracked terraform.tfvars file.
variable "alert_email" {
  description = "Email address that receives alarm notifications."
  type        = string
  sensitive   = true
}

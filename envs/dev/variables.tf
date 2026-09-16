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

terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "moyo-aws-lab-tfstate"
    key          = "aws-terraform-lab/dev/terraform.tfstate"
    region       = "eu-west-2"
    profile      = "personal"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      project      = var.project
      env          = var.env
      owner        = var.owner
      "managed-by" = "terraform"
    }
  }
}

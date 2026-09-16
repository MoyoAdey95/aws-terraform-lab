# Container registry for the app image.
#
# Tags are immutable, so v1 can never be silently replaced by a different
# image under the same name. When a build is wrong it gets a new tag, and the
# broken one stays visible, which is how v1 and v2 were kept apart in
# k8s-observability-lab. CI will tag by commit SHA for the same reason.
#
# force_delete lets terraform destroy remove the repository while images are
# still in it. Without it, teardown stops with RepositoryNotEmptyException.

resource "aws_ecr_repository" "app" {
  name                 = "${var.name_prefix}-api"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  # Basic scanning, which ECR includes at no charge. Enhanced scanning runs
  # through Amazon Inspector and is billed separately.
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.name_prefix}-api"
  }
}

# Untagged images are left behind whenever a layer push is interrupted or a
# build is superseded, and they bill for storage like any other. They go after
# a day. Beyond that, only the most recent images are kept.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after one day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the ${var.keep_image_count} most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_image_count
        }
        action = { type = "expire" }
      }
    ]
  })
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "fastapi-fargate"
      ManagedBy = "terraform"
      Stack     = "bootstrap"
    }
  }
}

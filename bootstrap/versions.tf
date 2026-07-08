terraform {
  required_version = "~> 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # bootstrap's own state, moved off the operator's machine and into S3.
  backend "s3" {
    bucket         = "fastapi-fargate-tfstate-429104603531"
    key            = "bootstrap/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "fastapi-fargate-tfstate-lock"
    encrypt        = true
  }
}

aws_region  = "ap-northeast-1"
name_prefix = "fastapi-fargate"
environment = "prod"

# No domain yet — ALB stays on HTTP(80). Set this once a domain is available.
domain_name = ""

# Real app image, pushed by GitHub Actions to the fastapi-fargate-app ECR repo.
container_image = "429104603531.dkr.ecr.ap-northeast-1.amazonaws.com/fastapi-fargate-app:latest"

# Fill these in before applying, so the GitHub Actions OIDC trust policy is scoped correctly.
github_org  = "h-fujiwara-dev"
github_repo = "fastAPI-fargate"

# Optional: set to receive CloudWatch alarm emails.
alert_email = "omeomeinuomeinu@gmail.com"

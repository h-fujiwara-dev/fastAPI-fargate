aws_region  = "ap-northeast-1"
name_prefix = "fastapi-fargate"
environment = "prod"

# No domain yet — ALB stays on HTTP(80). Set this once a domain is available.
domain_name = ""

# Fill these in before applying, so the GitHub Actions OIDC trust policy is scoped correctly.
github_org  = "h-fujiwara-dev"
github_repo = "fastAPI-fargate"

# Optional: set to receive CloudWatch alarm emails.
alert_email = "omeomeinuomeinu@gmail.com"

# Fill these in from `terraform output` in bootstrap/ after it has been applied,
# then run: terraform init -backend-config=backend.hcl
bucket         = "fastapi-fargate-tfstate-429104603531"
key            = "prod/terraform.tfstate"
region         = "ap-northeast-1"
dynamodb_table = "fastapi-fargate-tfstate-lock"
encrypt        = true

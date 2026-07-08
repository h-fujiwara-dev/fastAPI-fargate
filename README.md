# fastapi-fargate

Terraform で構築する AWS インフラ一式。

```
User -> (Route 53: future) -> AWS WAF -> ALB (public subnet)
     -> ECS Fargate / FastAPI (private app subnet)
     -> RDS PostgreSQL (private db subnet)
Backing services: CloudWatch monitoring, GitHub Actions (OIDC) -> ECR -> ECS deploy
```

## Directory layout

- `bootstrap/` — creates the S3 bucket + DynamoDB table used for remote Terraform state. Run once, uses local state.
- `envs/prod/` — the main stack (VPC, WAF, ALB, ECS, RDS, CloudWatch, GitHub OIDC role). Uses the S3 backend created by `bootstrap/`.
- `modules/*` — reusable modules called from `envs/prod`.
- `.github/workflows/deploy.yml` — builds the app image, pushes to ECR, and forces a new ECS deployment via GitHub Actions OIDC (no long-lived AWS keys).

## First-time setup

1. `cd bootstrap && terraform init && terraform apply`
2. Add an `s3` backend block to `bootstrap/versions.tf` pointing at the bucket/table just created, then run `terraform init -migrate-state` (moves bootstrap's own state off your laptop and into S3).
3. Copy the bucket/table names from the bootstrap outputs into `envs/prod/backend.hcl`.
4. `cd ../envs/prod && terraform init -backend-config=backend.hcl`
5. `terraform plan` then `terraform apply`.
6. Confirm the SNS email subscription (check your inbox).
7. `curl http://$(terraform output -raw alb_dns_name)/` to confirm the placeholder container responds.
8. Add `terraform output -raw github_actions_role_arn` as the `AWS_ROLE_ARN` repository variable in GitHub (Settings > Secrets and variables > Actions > Variables).
9. Set `container_image = "<terraform output -raw ecr_repository_url>:latest"` in `envs/prod/terraform.tfvars` and re-apply, so the ECS task definition points at your own ECR repo instead of the placeholder image. The deploy workflow only pushes to the `:latest`/`:sha-<sha>` tags and calls `force-new-deployment` — it does not register a new task definition, so the task definition's image reference must already be the mutable `:latest` tag for new pushes to actually take effect.
10. Push your FastAPI app's Dockerfile to `main` — GitHub Actions will build, push to ECR, and roll the ECS service.

## Notes

- No domain is configured yet, so the ALB only listens on HTTP (80). Set `domain_name` in `envs/prod/terraform.tfvars` once a domain is available to add Route 53 + ACM + an HTTPS (443) listener.
- The database is a single-AZ `db.t4g.micro` RDS for PostgreSQL instance, chosen for cost over availability. Flip `db_multi_az = true` later if needed.
- A single NAT Gateway is used (cost over multi-AZ resilience for outbound traffic).
- The ECS task definition starts out pointing at a placeholder public image (`container_image` variable) until the real app image is pushed to ECR.

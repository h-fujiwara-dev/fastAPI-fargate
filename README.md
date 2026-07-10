# fastapi-fargate

Terraform で構築する AWS インフラ一式。

## Architecture

![AWS architecture: a client request passes through WAF and an ALB into an ECS Fargate service running FastAPI, across public / private-app / private-db subnet tiers in 2 AZs, down to a single-AZ RDS PostgreSQL instance with no internet route; a second, separate ALB fronts a WordPress ECS service in the same cluster, backed by its own RDS MySQL instance and an EFS volume for wp-content, and the WordPress plugin calls the FastAPI ALB over the public internet with an X-API-Key header, the same as any other client; two separate GitHub Actions pipelines build and push images to their own ECR repos and redeploy their respective ECS services via OIDC; CloudWatch/SNS monitor the FastAPI side of the stack.](docs/architecture.svg)

- **Request flow (FastAPI)**: Client → WAF → ALB (public subnets) → ECS Fargate (private app subnets) → RDS PostgreSQL (private db subnets, no internet route).
- **Security group chain**: `alb-sg → ecs-sg → db-sg` — each tier's security group only trusts the previous tier's security group as its source.
- **Credentials**: the ECS task execution role reads the RDS-managed master password from Secrets Manager; the app never sees a plaintext password in Terraform state.
- **API auth**: `/items` requires an `X-API-Key` header. Terraform generates a random key into Secrets Manager and injects it into the task as `APP_API_KEY`; retrieve it with `aws secretsmanager get-secret-value --secret-id $(terraform output -raw api_key_secret_arn) --query SecretString --output text`. `/` (the ALB health check) stays open.
- **Egress-only path**: ECS tasks have no direct internet route — outbound traffic (e.g. pulling public resources, calling AWS APIs) goes through the single NAT Gateway and the Internet Gateway.
- **CI/CD**: GitHub Actions assumes an IAM role via OIDC (no long-lived AWS keys), builds and pushes the app image to ECR, then redeploys the ECS service. See setup step 9 below for an important caveat about how this deploy step works.
- **Monitoring**: ECS/ALB/RDS metrics feed CloudWatch alarms, which publish to an SNS topic with an email subscription.
- **HTTPS is not active yet** — `modules/dns_cert` (Route 53 + ACM) exists in code but isn't wired up because no domain is configured; see `Notes` below.

### WordPress frontend

A read-only WordPress plugin (list/detail view of Items) runs as a second ECS Fargate service in the **same cluster**, fronted by its **own, separate ALB**. It's independent infrastructure layered on top of the above — nothing in the FastAPI stack changes for it.

- **Request flow (WordPress)**: Client → WordPress ALB (public subnets, HTTP only, no WAF) → ECS Fargate WordPress service (private app subnets) → RDS MySQL (private db subnets, no internet route) for WordPress core data, and EFS (mounted at `wp-content`, private app subnets) for themes/plugins/uploads persistence across task restarts.
- **Calling the FastAPI API**: the `fastapi-items-viewer` plugin calls the *existing, public* FastAPI ALB from PHP server-side (`wp_remote_get()`), sending `X-API-Key` — the same path any other client would use, over the internet and through WAF. This is intentional: WordPress and FastAPI are not given a private/internal network path to each other, keeping the FastAPI-side infra completely unchanged. The API key is injected into the WordPress task as `FASTAPI_API_KEY` (same Secrets Manager secret as `APP_API_KEY` above) and is never sent to the browser.
- **Isolation from the FastAPI app**: WordPress has its own security groups end-to-end (`wp-alb-sg → wp-ecs-sg → wp-db-sg` / `wp-ecs-sg → efs-sg`); the only thing it shares with the FastAPI app is the ECS cluster and the API key secret (read-only, via a separate IAM role).
- **No HTTPS/domain** for the WordPress ALB either, same as FastAPI.
- **CI/CD**: a separate GitHub Actions workflow (`deploy-wordpress.yml`, path-filtered on `wordpress/**`) builds `wordpress/Dockerfile` and redeploys the WordPress ECS service, using its own narrowly-scoped OIDC role.

## Directory layout

- `bootstrap/` — creates the S3 bucket + DynamoDB table used for remote Terraform state. Run once, uses local state.
- `envs/prod/` — the main stack (VPC, WAF, ALB, ECS, RDS, CloudWatch, GitHub OIDC role). Uses the S3 backend created by `bootstrap/`.
- `modules/*` — reusable modules called from `envs/prod`.
- `.github/workflows/deploy.yml` — builds the app image, pushes to ECR, and forces a new ECS deployment via GitHub Actions OIDC (no long-lived AWS keys).
- `app/` — the FastAPI application (async SQLAlchemy + a sample `items` CRUD resource backed by RDS PostgreSQL).
- `alembic/` — database migrations (async Alembic, targets the same RDS instance as the app).
- `wordpress/` — the WordPress frontend: `Dockerfile` + `docker-entrypoint-wrapper.sh` (bakes and force-refreshes the plugin and theme on every container start) + `wp-content/plugins/fastapi-items-viewer/` (the read-only Items list/detail plugin) + `wp-content/themes/eye-spy/` (the site theme: a blue/cream look with a large mouse-tracking eye card as the front page hero).
- `.github/workflows/deploy-wordpress.yml` — builds the WordPress image, pushes to its own ECR repo, and forces a new deployment of the WordPress ECS service (separate OIDC role from the FastAPI pipeline).
- `docs/` — architecture diagram (draw.io source `architecture.drawio` + exported `architecture.svg`, see Architecture above).

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

### WordPress

The same `terraform apply` above also stands up the WordPress ALB/ECS service/RDS/EFS, starting from the stock public WordPress image (no custom plugin baked in yet):

11. `curl http://$(terraform output -raw wp_alb_dns_name)/` to confirm the stock WordPress container responds (redirects to the install wizard).
12. Add `terraform output -raw wp_github_actions_role_arn` as the `WORDPRESS_AWS_ROLE_ARN` repository variable in GitHub — a separate variable from `AWS_ROLE_ARN`, since WordPress uses its own, narrowly-scoped OIDC role.
13. Set `wp_container_image = "<terraform output -raw wp_ecr_repository_url>:latest"` in `envs/prod/terraform.tfvars` and re-apply, so the task definition points at your own image (with the `fastapi-items-viewer` plugin and `eye-spy` theme baked in) instead of the stock public one. Same `:latest`/`force-new-deployment` caveat as step 9 above.
14. Push a change under `wordpress/` to `main` — `deploy-wordpress.yml` will build, push to the `fastapi-fargate-wordpress` ECR repo, and roll the WordPress ECS service.
15. In wp-admin, add the `[fastapi_items]` shortcode to a page to render the Items list/detail view. If `FASTAPI_API_BASE_URL`/`FASTAPI_API_KEY` aren't set as task env vars, configure them instead under Settings > FastAPI Items.
16. In wp-admin, activate the **Eye Spy** theme under Appearance > Themes. This is one-time: unlike the plugin/theme *files* (force-refreshed from the image on every deploy), the active-theme choice lives in the database and persists across future deploys.

## Database migrations

RDS lives in the deepest private subnet with no route to the internet, so `alembic upgrade head` can't be run from a laptop — it has to run from inside the VPC. The simplest way is a one-off ECS task that reuses the app's own task definition (same image, same network access to RDS) but overrides the container command:

```
aws ecs run-task \
  --cluster fastapi-fargate-cluster \
  --task-definition fastapi-fargate-task \
  --launch-type FARGATE \
  --network-configuration '{"awsvpcConfiguration":{"subnets":["<private-app-subnet-id>"],"securityGroups":["<ecs-sg-id>"],"assignPublicIp":"DISABLED"}}' \
  --overrides '{"containerOverrides":[{"name":"app","command":["alembic","upgrade","head"]}]}'
```

Get the subnet/security group IDs from `terraform output` or the AWS console. Run this once after the first real app image is deployed, and again after any migration is added.

## Notes

- No domain is configured yet, so the ALB only listens on HTTP (80). Set `domain_name` in `envs/prod/terraform.tfvars` once a domain is available to add Route 53 + ACM + an HTTPS (443) listener.
- The database is a single-AZ `db.t4g.micro` RDS for PostgreSQL instance, chosen for cost over availability. Flip `db_multi_az = true` later if needed.
- A single NAT Gateway is used (cost over multi-AZ resilience for outbound traffic).
- The ECS task definition starts out pointing at a placeholder public image (`container_image` variable) until the real app image is pushed to ECR.
- When the Terraform architecture changes, update `docs/architecture.drawio` and re-export `docs/architecture.svg` before merging, so the diagram doesn't drift from reality.

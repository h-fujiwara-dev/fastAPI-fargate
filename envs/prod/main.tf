module "vpc" {
  source = "../../modules/vpc"

  name_prefix        = var.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  tags               = local.common_tags
}

module "waf" {
  source = "../../modules/waf"

  name_prefix = var.name_prefix
  tags        = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix       = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  container_port    = var.container_port
  enable_https      = local.enable_https
  certificate_arn   = local.enable_https ? module.dns_cert[0].certificate_arn : null
  tags              = local.common_tags
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = module.alb.alb_arn
  web_acl_arn  = module.waf.web_acl_arn
}

module "dns_cert" {
  count  = local.enable_https ? 1 : 0
  source = "../../modules/dns_cert"

  domain_name        = var.domain_name
  create_hosted_zone = var.create_hosted_zone
  alb_dns_name       = module.alb.alb_dns_name
  alb_zone_id        = module.alb.alb_zone_id
  tags               = local.common_tags
}

resource "random_password" "api_key" {
  length  = 40
  special = false
}

resource "aws_secretsmanager_secret" "api_key" {
  name = "${var.name_prefix}-api-key"
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = random_password.api_key.result
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix = var.name_prefix
  tags        = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix           = var.name_prefix
  vpc_id                = module.vpc.vpc_id
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  ecs_sg_id             = module.ecs.ecs_sg_id
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  database_name         = var.db_name
  master_username       = var.db_master_username
  multi_az              = var.db_multi_az
  deletion_protection   = var.db_deletion_protection
  skip_final_snapshot   = var.db_skip_final_snapshot
  tags                  = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix            = var.name_prefix
  aws_region             = var.aws_region
  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  alb_sg_id              = module.alb.alb_sg_id
  target_group_arn       = module.alb.target_group_arn
  container_image        = var.container_image
  container_port         = var.container_port
  cpu                    = var.ecs_cpu
  memory                 = var.ecs_memory
  desired_count          = var.ecs_desired_count
  min_capacity           = var.ecs_min_capacity
  max_capacity           = var.ecs_max_capacity
  db_host                = module.rds.db_address
  db_port                = module.rds.db_port
  db_name                = module.rds.db_name
  db_secret_arn          = module.rds.secret_arn
  api_key_secret_arn     = aws_secretsmanager_secret.api_key.arn
  tags                   = local.common_tags
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  name_prefix             = var.name_prefix
  alert_email             = var.alert_email
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  db_instance_id          = module.rds.db_instance_id
  tags                    = local.common_tags
}

module "github_oidc" {
  source = "../../modules/github_oidc"

  name_prefix             = var.name_prefix
  create_oidc_provider    = var.create_oidc_provider
  github_org              = var.github_org
  github_repo             = var.github_repo
  allowed_branch          = var.allowed_branch
  ecr_repository_arn      = module.ecr.repository_arn
  task_execution_role_arn = module.ecs.task_execution_role_arn
  task_role_arn           = module.ecs.task_role_arn
  tags                    = local.common_tags
}

# ==========================================================================
# WordPress — new resources only, added alongside the FastAPI app above.
# Nothing above this line is modified for WordPress. WordPress calls the
# FastAPI app over its existing public ALB (module.alb), like any client.
# ==========================================================================

module "alb_wordpress" {
  source = "../../modules/alb"

  name_prefix       = local.wp_name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  container_port    = var.wp_container_port
  enable_https      = false
  tags              = local.common_tags
}

module "ecr_wordpress" {
  source = "../../modules/ecr"

  name_prefix     = local.wp_name_prefix
  repository_name = "${var.name_prefix}-wordpress"
  tags            = local.common_tags
}

# WordPress unique auth keys/salts — generated once, injected as env vars so
# sessions/cookies survive task restarts. Never exposed outside the ECS task.
resource "random_password" "wp_auth_key" {
  length = 64
}

resource "random_password" "wp_secure_auth_key" {
  length = 64
}

resource "random_password" "wp_logged_in_key" {
  length = 64
}

resource "random_password" "wp_nonce_key" {
  length = 64
}

resource "random_password" "wp_auth_salt" {
  length = 64
}

resource "random_password" "wp_secure_auth_salt" {
  length = 64
}

resource "random_password" "wp_logged_in_salt" {
  length = 64
}

resource "random_password" "wp_nonce_salt" {
  length = 64
}

resource "aws_secretsmanager_secret" "wp_salts" {
  name = "${local.wp_name_prefix}-salts"
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "wp_salts" {
  secret_id = aws_secretsmanager_secret.wp_salts.id
  secret_string = jsonencode({
    AUTH_KEY         = random_password.wp_auth_key.result
    SECURE_AUTH_KEY  = random_password.wp_secure_auth_key.result
    LOGGED_IN_KEY    = random_password.wp_logged_in_key.result
    NONCE_KEY        = random_password.wp_nonce_key.result
    AUTH_SALT        = random_password.wp_auth_salt.result
    SECURE_AUTH_SALT = random_password.wp_secure_auth_salt.result
    LOGGED_IN_SALT   = random_password.wp_logged_in_salt.result
    NONCE_SALT       = random_password.wp_nonce_salt.result
  })
}

module "rds_mysql" {
  source = "../../modules/rds_mysql"

  name_prefix           = local.wp_name_prefix
  vpc_id                = module.vpc.vpc_id
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  wordpress_ecs_sg_id   = module.ecs_wordpress.ecs_sg_id
  engine_version        = var.wp_db_engine_version
  instance_class        = var.wp_db_instance_class
  allocated_storage     = var.wp_db_allocated_storage
  database_name         = var.wp_db_name
  master_username       = var.wp_db_master_username
  multi_az              = var.wp_db_multi_az
  deletion_protection   = var.wp_db_deletion_protection
  skip_final_snapshot   = var.wp_db_skip_final_snapshot
  tags                  = local.common_tags
}

module "efs" {
  source = "../../modules/efs"

  name_prefix            = local.wp_name_prefix
  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  wordpress_ecs_sg_id    = module.ecs_wordpress.ecs_sg_id
  tags                   = local.common_tags
}

module "ecs_wordpress" {
  source = "../../modules/ecs_wordpress"

  name_prefix            = local.wp_name_prefix
  aws_region             = var.aws_region
  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  cluster_name           = module.ecs.cluster_name
  alb_sg_id              = module.alb_wordpress.alb_sg_id
  target_group_arn       = module.alb_wordpress.target_group_arn
  container_image        = var.wp_container_image
  container_port         = var.wp_container_port
  cpu                    = var.wp_ecs_cpu
  memory                 = var.wp_ecs_memory
  desired_count          = var.wp_ecs_desired_count
  min_capacity           = var.wp_ecs_min_capacity
  max_capacity           = var.wp_ecs_max_capacity
  db_host                = module.rds_mysql.db_address
  db_port                = module.rds_mysql.db_port
  db_name                = module.rds_mysql.db_name
  db_secret_arn          = module.rds_mysql.secret_arn
  api_key_secret_arn     = aws_secretsmanager_secret.api_key.arn
  wp_salts_secret_arn    = aws_secretsmanager_secret.wp_salts.arn
  fastapi_alb_dns_name   = module.alb.alb_dns_name
  wordpress_alb_dns_name = module.alb_wordpress.alb_dns_name
  efs_file_system_id     = module.efs.file_system_id
  efs_file_system_arn    = module.efs.file_system_arn
  efs_access_point_id    = module.efs.access_point_id
  efs_access_point_arn   = module.efs.access_point_arn
  tags                   = local.common_tags
}

module "github_oidc_wordpress" {
  source = "../../modules/github_oidc"

  name_prefix             = local.wp_name_prefix
  create_oidc_provider    = false
  github_org              = var.github_org
  github_repo             = var.github_repo
  allowed_branch          = var.allowed_branch
  ecr_repository_arn      = module.ecr_wordpress.repository_arn
  task_execution_role_arn = module.ecs_wordpress.task_execution_role_arn
  task_role_arn           = module.ecs_wordpress.task_role_arn
  tags                    = local.common_tags
}

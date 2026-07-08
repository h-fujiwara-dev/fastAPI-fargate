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

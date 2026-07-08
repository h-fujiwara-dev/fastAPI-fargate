output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "db_address" {
  value = module.rds.db_address
}

output "db_secret_arn" {
  value     = module.rds.secret_arn
  sensitive = true
}

output "github_actions_role_arn" {
  value = module.github_oidc.github_actions_role_arn
}

output "waf_web_acl_arn" {
  value = module.waf.web_acl_arn
}

output "api_key_secret_arn" {
  description = "Fetch the value with: aws secretsmanager get-secret-value --secret-id <this arn> --query SecretString --output text"
  value       = aws_secretsmanager_secret.api_key.arn
}

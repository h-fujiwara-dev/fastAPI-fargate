variable "name_prefix" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "cluster_name" {
  description = "Name of the existing ECS cluster to deploy this service into. This module does not create a cluster."
  type        = string
}

variable "alb_sg_id" {
  description = "Security group ID of the WordPress ALB."
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN of the WordPress ALB."
  type        = string
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type    = number
  default = 80
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 2
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type = number
}

variable "db_name" {
  type = string
}

variable "db_secret_arn" {
  description = "ARN of the RDS-managed master user secret for the WordPress MySQL database."
  type        = string
}

variable "api_key_secret_arn" {
  description = "ARN of the existing FastAPI app's API key secret (see envs/prod/main.tf) — reused as-is, never modified."
  type        = string
}

variable "wp_salts_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the 8 WordPress auth keys/salts as a JSON object."
  type        = string
}

variable "fastapi_alb_dns_name" {
  description = "DNS name of the existing, public FastAPI ALB the plugin calls over the internet."
  type        = string
}

variable "wordpress_alb_dns_name" {
  description = "DNS name of this WordPress service's own ALB, used for WP_HOME/WP_SITEURL."
  type        = string
}

variable "efs_file_system_id" {
  type = string
}

variable "efs_file_system_arn" {
  type = string
}

variable "efs_access_point_id" {
  type = string
}

variable "efs_access_point_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

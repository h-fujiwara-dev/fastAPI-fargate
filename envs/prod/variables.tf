variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "name_prefix" {
  type    = string
  default = "fastapi-fargate"
}

variable "environment" {
  type    = string
  default = "prod"
}

# ---- Networking ----

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}

# ---- DNS / TLS (future) ----

variable "domain_name" {
  description = "Leave empty to run the ALB on HTTP only. Set once a domain is available to add Route 53 + ACM + HTTPS."
  type        = string
  default     = ""
}

variable "create_hosted_zone" {
  type    = bool
  default = false
}

# ---- ECS / app ----

variable "container_image" {
  type    = string
  default = "public.ecr.aws/nginx/nginx:latest"
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "ecs_cpu" {
  type    = number
  default = 256
}

variable "ecs_memory" {
  type    = number
  default = 512
}

variable "ecs_desired_count" {
  type    = number
  default = 2
}

variable "ecs_min_capacity" {
  type    = number
  default = 1
}

variable "ecs_max_capacity" {
  type    = number
  default = 4
}

# ---- Database ----

variable "db_engine_version" {
  type    = string
  default = "16.14"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "app"
}

variable "db_master_username" {
  type    = string
  default = "app_admin"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

# ---- WordPress ----

variable "wp_container_image" {
  description = "Starts pointing at the stock public WordPress image; switch to the ECR image built from wordpress/Dockerfile once it's pushed."
  type        = string
  default     = "wordpress:6.9.4-php8.3-apache"
}

variable "wp_container_port" {
  type    = number
  default = 80
}

variable "wp_ecs_cpu" {
  type    = number
  default = 512
}

variable "wp_ecs_memory" {
  type    = number
  default = 1024
}

variable "wp_ecs_desired_count" {
  type    = number
  default = 1
}

variable "wp_ecs_min_capacity" {
  type    = number
  default = 1
}

variable "wp_ecs_max_capacity" {
  type    = number
  default = 2
}

variable "wp_db_engine_version" {
  type    = string
  default = "8.4.10"
}

variable "wp_db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "wp_db_allocated_storage" {
  type    = number
  default = 20
}

variable "wp_db_name" {
  type    = string
  default = "wordpress"
}

variable "wp_db_master_username" {
  type    = string
  default = "wp_admin"
}

variable "wp_db_multi_az" {
  type    = bool
  default = false
}

variable "wp_db_deletion_protection" {
  type    = bool
  default = false
}

variable "wp_db_skip_final_snapshot" {
  type    = bool
  default = true
}

# ---- CI/CD ----

variable "github_org" {
  type    = string
  default = ""
}

variable "github_repo" {
  type    = string
  default = ""
}

variable "allowed_branch" {
  type    = string
  default = "main"
}

variable "create_oidc_provider" {
  type    = bool
  default = true
}

# ---- Monitoring ----

variable "alert_email" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

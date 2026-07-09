variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "wordpress_ecs_sg_id" {
  description = "Security group ID of the WordPress ECS service allowed to reach the database."
  type        = string
}

variable "engine_version" {
  type    = string
  default = "8.4.10"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "database_name" {
  type    = string
  default = "wordpress"
}

variable "master_username" {
  type    = string
  default = "wp_admin"
}

variable "multi_az" {
  description = "Cost-priority default is single-AZ. Set true later for automatic failover."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  # 1 day is the max allowed on AWS Free Tier-restricted accounts;
  # raise this once the account is off Free Tier restrictions.
  type    = number
  default = 1
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
